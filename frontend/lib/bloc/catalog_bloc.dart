import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/api.dart';
import '../data/models.dart';

sealed class CatalogEvent {
  const CatalogEvent();
}

/// Филтр иваз шуд — рӯйхат аз нав бор мешавад.
class CatalogFilterChanged extends CatalogEvent {
  const CatalogFilterChanged(this.filter);
  final ListingFilter filter;
}

/// Саҳифаи навбатӣ (скролли бепоён).
class CatalogNextPage extends CatalogEvent {
  const CatalogNextPage();
}

enum CatalogStatus { loading, ready, failure }

class CatalogState extends Equatable {
  const CatalogState({
    this.filter = const ListingFilter(),
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.status = CatalogStatus.loading,
    this.loadingMore = false,
    this.error,
  });

  final ListingFilter filter;
  final List<Listing> items;
  final int total;
  final int page;
  final CatalogStatus status;
  final bool loadingMore;
  final String? error;

  bool get hasMore => items.length < total;

  CatalogState copyWith({
    ListingFilter? filter,
    List<Listing>? items,
    int? total,
    int? page,
    CatalogStatus? status,
    bool? loadingMore,
    String? error,
  }) =>
      CatalogState(
        filter: filter ?? this.filter,
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        status: status ?? this.status,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error,
      );

  @override
  List<Object?> get props => [filter, items, total, page, status, loadingMore, error];
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc(this._api, ListingFilter initial) : super(CatalogState(filter: initial)) {
    on<CatalogFilterChanged>(_onFilter, transformer: restartable());
    on<CatalogNextPage>(_onNext, transformer: droppable());
  }

  final TilloApi _api;
  static const perPage = 24;

  Future<void> _onFilter(CatalogFilterChanged e, Emitter<CatalogState> emit) async {
    emit(state.copyWith(filter: e.filter, status: CatalogStatus.loading));
    try {
      final page = await _api.listings(e.filter.toQuery(), perPage: perPage);
      emit(state.copyWith(items: page.items, total: page.total, page: 1, status: CatalogStatus.ready));
    } on ApiException catch (err) {
      emit(state.copyWith(status: CatalogStatus.failure, error: err.message));
    }
  }

  Future<void> _onNext(CatalogNextPage e, Emitter<CatalogState> emit) async {
    if (!state.hasMore || state.status != CatalogStatus.ready) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _api.listings(state.filter.toQuery(), page: state.page + 1, perPage: perPage);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        total: page.total,
        page: page.page,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }
}
