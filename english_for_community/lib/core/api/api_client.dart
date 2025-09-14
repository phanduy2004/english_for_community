import 'package:dio/dio.dart';
import 'package:english_for_community/core/api/token_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_config.dart';
class ApiClient{
  Dio getDio({bool tokenInterceptor = false}){
    Dio dio = Dio();
    dio.options.baseUrl = '${ApiConfig.Base_URL}api/';

    dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestBody: true,
      requestHeader: true,
      responseBody: true,
      responseHeader: true,
      compact: false
    ));
    return dio;
  }
}