import 'dart:convert';

import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/projects/projects_controller.dart';
import 'package:cineconnect/core/projects/projects_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('successful project creation survives a failed list refresh', () async {
    var createCount = 0;
    final client = ApiClient(
      baseUrl: 'https://cine.test/api/v1',
      httpClient: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/projects')) {
          createCount++;
          expect(jsonDecode(request.body)['status'], 'draft');
          return http.Response(
            jsonEncode({
              'data': {
                'project': {
                  'public_id': 'PRJ-SAVED',
                  'title': 'Saved project',
                  'project_type': 'film',
                  'status': 'draft',
                },
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'error': {'code': 'network.retry', 'message': 'Retry'}
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final controller =
        ProjectsController(repository: ProjectsRepository(client));

    final project = await controller.createProject(
      title: 'Saved project',
      projectType: 'film',
      status: 'draft',
    );

    expect(project.publicId, 'PRJ-SAVED');
    expect(controller.cachedProjects, isNull);
    expect(createCount, 1);
  });
}
