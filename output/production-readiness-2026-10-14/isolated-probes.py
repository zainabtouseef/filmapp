"""Isolated readiness probes. SQLite + temporary storage only; no production writes."""
import json,tempfile,pathlib,sys,datetime
sys.path.insert(0,str(pathlib.Path.cwd()/'backend'))
from sqlalchemy.dialects.mysql import LONGTEXT
from sqlalchemy.ext.compiler import compiles
from sqlalchemy import select
from app import create_app
from app.config import TestConfig
from app.extensions import db,limiter
from app.models.identity import User,Role,UserRole,UserSession
from app.models.projects import Project,ProjectMember,ProjectFile
from app.models.operations import SafetyCheck,SafetyCheckItem
from app.models.bookings import Booking
from app.models.marketplace import MarketplaceListing
from app.models.payments import PaymentSchedule,PaymentMilestone,PaymentTransaction,PaymentProof
from app.models.base import utc_now
from datetime import timedelta
from app.security import issue_token_pair,rotate_refresh_token
@compiles(LONGTEXT,'sqlite')
def compile_longtext(*args,**kw):return 'TEXT'
tmp=tempfile.TemporaryDirectory(prefix='cine-readiness-')
class C(TestConfig):
 SQLALCHEMY_DATABASE_URI='sqlite:///'+tmp.name+'/audit.db'
 SQLALCHEMY_ENGINE_OPTIONS={}
 LOCAL_STORAGE_PRIVATE_ROOT=tmp.name+'/private'
 LOCAL_STORAGE_PUBLIC_ROOT=tmp.name+'/public'
 @classmethod
 def validate(cls,_):pass
app=create_app(C);client=app.test_client();results=[]
with app.test_request_context():
 db.create_all();users={};tokens={}
 for name,code in [('owner','director_producer'),('viewer','actor_talent'),('inactive','general_public'),('staff','support_agent'),('admin','super_admin')]:
  role=Role(code=code,name=code,portal_route='/test');db.session.add(role);db.session.flush()
  u=User(email=name+'@example.com',display_name=name,password_hash='audit-fixture',terms_version='2026-10');db.session.add(u);db.session.flush()
  db.session.add(UserRole(user_id=u.id,role_id=role.id,status='active',is_primary=True));db.session.flush();users[name]=u;tokens[name]=issue_token_pair(u)
 p=Project(owner_user_id=users['owner'].id,title='Isolated audit',project_type='film');db.session.add(p);db.session.flush()
 for name in ['owner','viewer','inactive']:
  db.session.add(ProjectMember(project_id=p.id,user_id=users[name].id,role_label='Viewer' if name!='owner' else 'Owner',status='removed' if name=='inactive' else 'active',permissions_json=json.dumps({'manage_project':False,'manage_members':False})))
 sc=SafetyCheck(project_id=p.id,responsible_user_id=users['owner'].id,risk_level='high');db.session.add(sc);db.session.flush()
 item=SafetyCheckItem(safety_check_id=sc.id,label='Mandatory safety approval',mandatory=True);db.session.add(item);db.session.flush()
 ids={'project':p.public_id,'check':sc.public_id,'item':str(item.id),'viewer':users['viewer'].public_id};db.session.commit()
 headers={k:{'Authorization':'Bearer '+v.access_token} for k,v in tokens.items()}
def check(name,role,method,path,payload=None,expected=None):
 r=client.open('/api/v1'+path,method=method,headers=headers.get(role,{}),json=payload)
 results.append({'probe':name,'method':method,'path':path.replace(ids['check'],'<check>').replace(ids['project'],'<project>').replace(ids['item'],'<item>').replace(ids['viewer'],'<viewer>'),'actual_status':r.status_code,'expected_secure_status':expected,'issue_reproduced':expected is not None and r.status_code!=expected})
 return r
check('Read-only member can change safety risk and completion','viewer','PATCH','/safety-checks/'+ids['check'],{'status':'completed','risk_level':'low'},403)
check('Read-only member can make mandatory safety item optional','viewer','PATCH','/safety-checks/'+ids['check']+'/items/'+ids['item'],{'mandatory':False},403)
check('Removed project member can create safety check','inactive','POST','/safety-checks',{'project_id':ids['project'],'risk_level':'low'},404)
check('Support role with zero permissions reads account directory','staff','GET','/admin/control/users',expected=403)
check('Regular member blocked from project settings','viewer','PATCH','/projects/'+ids['project'],{'title':'Unauthorized'},403)
check('Unrelated support user denied private safety check','staff','GET','/safety-checks/'+ids['check'],expected=404)
before=client.get('/api/v1/admin/control/audit-events',headers=headers['admin']).json['data']['events']
check('Admin suspends account in isolated test','admin','PATCH','/admin/control/users/'+ids['viewer'],{'status':'suspended'},200)
after=client.get('/api/v1/admin/control/audit-events',headers=headers['admin']).json['data']['events']
results.append({'probe':'Account suspension creates visible admin audit record','events_before':len(before),'events_after':len(after),'issue_reproduced':len(after)==len(before)})
with app.test_request_context():
 u,pair=rotate_refresh_token(tokens['owner'].refresh_token);db.session.commit()
 try:rotate_refresh_token(tokens['owner'].refresh_token);rejected=False
 except ValueError:rejected=True
 session=db.session.scalar(select(UserSession).where(UserSession.user_id==u.id))
 results.append({'probe':'Refresh token replay rejects old token and revokes family','old_token_rejected':rejected,'session_revoked':session.revoked_at is not None,'issue_reproduced':rejected and session.revoked_at is None})
 db.session.rollback()
with app.app_context():
 p=db.session.scalar(select(Project));p.status='active';p.visibility='private';p.estimated_budget_minor=12345000
 db.session.add(ProjectFile(project_id=p.id,folder='trailer',label='Private draft trailer',external_url='https://www.youtube.com/watch?v=aqz-KE-bpKQ',visibility='project_members',uploaded_by=p.owner_user_id));db.session.commit()
r=client.get('/api/v1/public/cinema');entries=r.json['data']['items']
results.append({'probe':'Private project member-only external trailer excluded from public cinema','public_items':len(entries),'private_budget_exposed':any(x['project'].get('estimated_budget_minor')==12345000 for x in entries),'issue_reproduced':len(entries)>0})
with app.app_context():
 admin=db.session.scalar(select(User).where(User.email=='admin@example.com'));owner=db.session.scalar(select(User).where(User.email=='owner@example.com'));p=db.session.scalar(select(Project))
 listing=MarketplaceListing(owner_user_id=owner.id,listing_type='talent',profile_entity_id='AUDIT-TALENT',verification_status='approved',moderation_status='approved',visibility='public',title='Audit listing',summary='Isolated')
 db.session.add(listing);db.session.flush()
 booking=Booking(project_id=p.id,requester_user_id=admin.id,provider_user_id=owner.id,listing_id=listing.id,category='talent',start_at=utc_now(),end_at=utc_now()+timedelta(hours=2),status='accepted')
 db.session.add(booking);db.session.flush()
 schedule=PaymentSchedule(booking_id=booking.id,total_minor=10000);db.session.add(schedule);db.session.flush()
 milestone=PaymentMilestone(schedule_id=schedule.id,name='Audit milestone',sequence=1,amount_minor=10000,release_condition='proof_verified');db.session.add(milestone);db.session.flush()
 transaction=PaymentTransaction(milestone_id=milestone.id,payer_user_id=admin.id,payee_user_id=owner.id,provider='bank_transfer',amount_minor=10000,idempotency_key='audit-self-review');db.session.add(transaction);db.session.flush()
 proof=PaymentProof(transaction_id=transaction.id,claimed_amount_minor=10000,method='bank_transfer',submitted_by=admin.id,status='pending');db.session.add(proof);db.session.flush();proof_id=proof.public_id;db.session.commit()
check('Payment submitter with admin role can approve own proof','admin','POST','/admin/payment-proofs/'+proof_id+'/decision',{'decision':'approved'},403)
route_counts={}
for r in app.url_map.iter_rules():
 group=r.endpoint.split('.')[1] if '.' in r.endpoint else r.endpoint
 route_counts[group]=route_counts.get(group,0)+1
out={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'isolation':'temporary SQLite; no production credentials; no delivery calls','probes':results,'route_counts':route_counts}
pathlib.Path('output/production-readiness-2026-10-14/isolated-probes.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
