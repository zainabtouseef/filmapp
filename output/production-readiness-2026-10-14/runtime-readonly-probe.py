import ast,json,pathlib,datetime,collections
from sqlalchemy import select,func,text
from app import create_app
from app.extensions import db,limiter
from app.models.identity import User
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from redis import Redis
app=create_app();out={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
with app.app_context():
 out['config_flags']={k:bool(app.config.get(k)) for k in ['SENTRY_DSN','SMTP_HOST','SMTP_FROM','VAPID_PUBLIC_KEY','VAPID_PRIVATE_KEY_FILE','OPENAI_API_KEY','CINEPLANNER_AI_ENABLED','FIELD_ENCRYPTION_KEY']}
 out['config_values']={k:app.config.get(k) for k in ['APP_ENV','PAYMENTS_MODE','PAYMENT_MODE','SMS_ENABLED','RATELIMIT_DEFAULT','ACCESS_TOKEN_MINUTES','REFRESH_TOKEN_DAYS']}
 out['secret_length_checks']={k:len(str(app.config.get(k,'')))>=64 for k in ['SECRET_KEY','JWT_SECRET_KEY']}
 out['migration']=db.session.execute(text('select version_num from alembic_version')).scalar_one()
 out['table_counts']={t:db.session.execute(text('select count(*) from '+t)).scalar_one() for t in ['users','files','bookings','contracts','payout_accounts','projects','marketplace_listings','notifications','user_sessions']}
 out['user_statuses']=[list(r) for r in db.session.execute(text('select status,count(*) from users group by status'))]
 out['files']=[list(r) for r in db.session.execute(text('select visibility,scan_status,processing_status,count(*) from files group by visibility,scan_status,processing_status'))]
 out['roles']=[list(r) for r in db.session.execute(text("select r.code,count(*) from user_roles ur join roles r on r.id=ur.role_id join users u on u.id=ur.user_id where ur.status='active' and u.status='active' group by r.code"))]
 out['db_transport']=list(db.session.execute(text("SHOW STATUS LIKE 'Ssl_cipher'")).one())
 out['db_privilege_types']=[r[0] for r in db.session.execute(text('SELECT PRIVILEGE_TYPE FROM information_schema.USER_PRIVILEGES WHERE GRANTEE=CONCAT(\'\'\'\',SUBSTRING_INDEX(CURRENT_USER(),\'@\',1),\'\'\'@\'\'\',SUBSTRING_INDEX(CURRENT_USER(),\'@\',-1),\'\'\'\')'))]
 out['routes']=[{'path':str(r),'methods':sorted(r.methods-{'OPTIONS','HEAD'}),'endpoint':r.endpoint} for r in app.url_map.iter_rules()]
 candidates=set()
 for path in list(pathlib.Path('scripts').glob('seed*.py'))+list(pathlib.Path('app/scripts').glob('seed*.py')):
  for n in ast.walk(ast.parse(path.read_text())):
   if isinstance(n,(ast.Assign,ast.AnnAssign)):
    targets=n.targets if isinstance(n,ast.Assign) else [n.target]
    if any(isinstance(t,ast.Name) and 'PASSWORD' in t.id for t in targets):
     for node in ast.walk(n.value):
      if isinstance(node,ast.Call) and isinstance(node.func,ast.Attribute) and node.func.attr=='getenv' and len(node.args)>1 and isinstance(node.args[1],ast.Constant) and isinstance(node.args[1].value,str): candidates.add(node.args[1].value)
 out['seed_password_candidates']=len(candidates)
 ph=PasswordHasher();matched=collections.Counter();matched_roles=collections.Counter();checked=0;malformed=0
 for u in db.session.scalars(select(User).where(User.status=='active')).all():
  checked+=1
  for p in candidates:
   try: ok=ph.verify(u.password_hash,p)
   except VerificationError:ok=False
   except Exception:malformed+=1;break
   if ok:
    matched['active_accounts']+=1
    for ur in u.roles:
     if ur.status=='active':matched_roles[ur.role.code]+=1
    break
 out['seed_password_matches']={'accounts_checked':checked,'matched':dict(matched),'active_role_assignments':dict(matched_roles),'malformed_hashes':malformed}
 redis=Redis.from_url(app.config['REDIS_URL']);keys=list(redis.scan_iter(match='LIMITS:*',count=100))[:500]
 out['rate_limit_redis']={'sampled_keys':len(keys),'loopback_keys':sum(b'127.0.0.1' in k for k in keys)}
 db.session.rollback()
out['rate_keys']=[]
for ip in ['198.51.100.11','198.51.100.22']:
 with app.test_request_context('/',headers={'X-Forwarded-For':ip},environ_base={'REMOTE_ADDR':'127.0.0.1'}):out['rate_keys'].append(limiter._key_func())
print(json.dumps(out,indent=2))
