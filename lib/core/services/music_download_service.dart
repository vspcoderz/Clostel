import '../models/track.dart';

abstract interface class MusicDownloadService {
  bool supports(Track track);

  Future<String> download(Track track);
}
