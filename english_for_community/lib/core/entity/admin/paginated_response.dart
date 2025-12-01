class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({required this.page, required this.limit, required this.total, required this.totalPages});

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationInfo pagination;

  PaginatedResponse({required this.data, required this.pagination});

  // dataKey là tên trường trong JSON chứa mảng dữ liệu (vd: 'users' hoặc 'reports')
  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      {required String dataKey}
      ) {
    return PaginatedResponse<T>(
      data: (json[dataKey] as List).map((e) => fromJsonT(e)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }
}