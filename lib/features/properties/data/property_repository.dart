import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/multipart_upload.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PropertyRepository(apiClient);
});

class PropertyRepository {
  const PropertyRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PropertyItem>> fetchProperties({
    String? search,
    String? type,
    String? city,
    String? availability,
    String? minRent,
    String? maxRent,
    int? bedrooms,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (city != null && city.isNotEmpty) {
      query['city'] = city;
    }
    if (availability != null && availability.isNotEmpty) {
      query['availability'] = availability;
    }
    if (minRent != null && minRent.isNotEmpty) {
      query['minRent'] = minRent;
    }
    if (maxRent != null && maxRent.isNotEmpty) {
      query['maxRent'] = maxRent;
    }
    if (bedrooms != null) {
      query['bedrooms'] = bedrooms;
    }

    final response = await _apiClient.get('/properties', queryParameters: query);

    return (response['data'] as List<dynamic>).map((e) => PropertyItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PropertyItem> fetchProperty(String id) async {
    final response = await _apiClient.get('/properties/$id');
    return PropertyItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<PropertyItem>> fetchManagedProperties() async {
    final response = await _apiClient.get('/admin/properties');
    return (response['data'] as List<dynamic>).map((e) => PropertyItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> uploadPropertyImages(List<PlatformFile> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files',
          await platformFileToMultipartFile(file),
        ),
      );
    }

    final response = await _apiClient.postForm('/uploads/property-images', formData);
    return (response['data'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Future<void> saveProperty(PropertyItem property, {String? id}) async {
    final payload = property.toCreatePayload();
    if (id == null) {
      await _apiClient.post('/properties', data: payload);
      return;
    }

    await _apiClient.patch('/properties/$id', data: payload);
  }

  Future<void> deleteProperty(String id) async {
    await _apiClient.delete('/properties/$id');
  }
}
