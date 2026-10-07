import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/area_models.dart';
import 'api_base.dart';

class AreaApi extends ApiBase {
  const AreaApi(super.dio);

  Future<ApiResponse<List<int>>> getRegional() async {
    try {
      final response = await dio.get(ApiConstants.areaRegional);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((e) => (e as num).toInt()).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<List<int>>> getWilayah() async {
    try {
      final response = await dio.get(ApiConstants.areaWilayah);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((e) => (e as num).toInt()).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  Future<ApiResponse<AreaEstateResponse>> getEstate() async {
    try {
      final response = await dio.get(ApiConstants.areaEstate);
      return ApiResponse.fromJson(
        response.data,
        (data) => AreaEstateResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}
