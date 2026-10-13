import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api.dart';
import '../data/models.dart';

// ---------------- Як эълон ----------------

class ListingState extends Equatable {
  const ListingState({this.listing, this.error});
  final Listing? listing;
  final String? error;
  @override
  List<Object?> get props => [listing, error];
}

class ListingCubit extends Cubit<ListingState> {
  ListingCubit(this._api, this.id) : super(const ListingState());
  final TilloApi _api;
  final int id;

  Future<void> load() async {
    emit(const ListingState());
    try {
      emit(ListingState(listing: await _api.listing(id)));
    } on ApiException catch (e) {
      emit(ListingState(error: e.message));
    }
  }
}

// ---------------- Рӯйхати оддӣ (асосӣ, дӯстдоштаҳо, эълонҳои ман) ----------------

class ListState extends Equatable {
  const ListState({this.items, this.error});
  final List<Listing>? items;
  final String? error;
  @override
  List<Object?> get props => [items, error];
}

class ListCubit extends Cubit<ListState> {
  ListCubit(this._api, this._query, {this.perPage = 12}) : super(const ListState());
  final TilloApi _api;
  final Map<String, String> Function() _query;
  final int perPage;

  Future<void> load() async {
    try {
      final page = await _api.listings(_query(), perPage: perPage);
      emit(ListState(items: page.items));
    } on ApiException catch (e) {
      emit(ListState(items: state.items, error: e.message));
    }
  }

  Future<void> delete(int id) async {
    await _api.deleteListing(id);
    emit(ListState(items: state.items?.where((l) => l.id != id).toList()));
  }
}

// ---------------- Илова кардани эълон ----------------

class PickedImage extends Equatable {
  const PickedImage({required this.bytes, required this.name, this.url});
  final Uint8List bytes;
  final String name;
  final String? url; // пас аз бор шудан
  bool get uploaded => url != null;
  @override
  List<Object?> get props => [name, url, bytes.length];
}

enum PostStatus { editing, sending, done }

class PostState extends Equatable {
  const PostState({this.images = const [], this.status = PostStatus.editing, this.error, this.created});
  final List<PickedImage> images;
  final PostStatus status;
  final String? error;
  final Listing? created;

  PostState copyWith({List<PickedImage>? images, PostStatus? status, String? error, Listing? created}) =>
      PostState(
        images: images ?? this.images,
        status: status ?? this.status,
        error: error,
        created: created ?? this.created,
      );

  @override
  List<Object?> get props => [images, status, error, created];
}

class PostCubit extends Cubit<PostState> {
  PostCubit(this._api, {ImagePicker? picker})
      : _picker = picker ?? ImagePicker(),
        super(const PostState());
  final TilloApi _api;
  final ImagePicker _picker;
  static const maxImages = 10;

  Future<void> pickImages() async {
    final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
    final room = maxImages - state.images.length;
    final picked = <PickedImage>[];
    for (final f in files.take(room)) {
      picked.add(PickedImage(bytes: await f.readAsBytes(), name: f.name));
    }
    emit(state.copyWith(images: [...state.images, ...picked]));
  }

  void removeImage(int index) =>
      emit(state.copyWith(images: [...state.images]..removeAt(index)));

  Future<void> submit(Map<String, dynamic> body) async {
    emit(state.copyWith(status: PostStatus.sending));
    try {
      final images = <PickedImage>[];
      for (final img in state.images) {
        images.add(img.uploaded
            ? img
            : PickedImage(bytes: img.bytes, name: img.name, url: await _api.upload(img.bytes, img.name)));
      }
      emit(state.copyWith(images: images, status: PostStatus.sending));
      final created = await _api.createListing({...body, 'images': images.map((i) => i.url).toList()});
      emit(state.copyWith(status: PostStatus.done, created: created));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PostStatus.editing, error: e.message));
    }
  }
}
