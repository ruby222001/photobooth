import 'dart:io';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:photoboothapp_new/pages/snackbar.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PhotoController extends GetxController {
  CameraController? cameraController;
  List<CameraDescription>? cameras;

  // var images = RxList<File?>([null, null, null, null]);
  var countdown = 0.obs;
  var isProcessing = false.obs;
  var activeSlot = 0.obs;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void onInit() {
    super.onInit();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      // Pick front camera if available, else first camera
      final frontCamera = cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      update();
    }
  }

  Future<void> switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    int currentIndex = cameras!.indexOf(cameraController!.description);
    int nextIndex = (currentIndex + 1) % cameras!.length;

    await cameraController!.dispose();
    cameraController = CameraController(
      cameras![nextIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await cameraController!.initialize();
    update();
  }

  /// Capture all 4 photos automatically with countdown
  Future<void> takePhotoSequence() async {
    cameraController!.value.isInitialized;
    if (isProcessing.value ||
        cameraController == null ||
        !cameraController!.value.isInitialized) return;

    isProcessing.value = true;

    try {
      for (int slot = 0; slot < images.length; slot++) {
        activeSlot.value = slot; // activate current grid
        images.refresh(); // force UI update
        await Future.delayed(const Duration(
            milliseconds: 200)); // small delay for UI to catch up

        countdown.value = 3;
        for (int i = 3; i > 0; i--) {
          countdown.value = i;
          await Future.delayed(const Duration(seconds: 1));
        }
        countdown.value = 0;

        final XFile? file = await cameraController?.takePicture();
        if (file != null && file.path.isNotEmpty) {
          images[slot] = File(file.path);
          images.refresh();
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      // After all photos taken, reset activeSlot
      activeSlot.value = -1;
    } finally {
      isProcessing.value = false;
    }
  }

  var images = RxList<File?>([null, null, null, null]); // 4 slots

  // Correct type: RxMap<int, RxList<StickerData>>
  var stickers = RxList<StickerData>();
  var stickerHistory = <List<StickerData>>[]; // For undo

  var selectedSticker = RxString("assets/milk.png"); // default sticker

  void addSticker({Offset? position}) {
    if (images.every((img) => img != null)) {
      _saveStickerHistory();
      stickers.add(StickerData(
        asset: selectedSticker.value,
        top: position?.dy ?? 150,
        left: position?.dx ?? 100,
      ));
    }
  }

  void undoSticker() {
    if (stickerHistory.isNotEmpty) {
      stickers.value = stickerHistory.removeLast();
    }
  }

  void _saveStickerHistory() {
    stickerHistory.add(stickers
        .map((s) => StickerData(asset: s.asset, top: s.top, left: s.left))
        .toList());
  }

  void updateStickerPosition(int index, double top, double left) {
    stickers[index].top = top;
    stickers[index].left = left;
    stickers.refresh();
  }

  void clearAll() {
    images.value = [null, null, null, null];
    activeSlot.value = 0;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        var status = await Permission.photos.request();
        return status.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11 & 12: MANAGE_EXTERNAL_STORAGE
        if (!await Permission.manageExternalStorage.isGranted) {
          // Open settings page for permission
          SSnackbarUtil.showSnackbar(
              "Permission Required",
              "Please enable 'All files access' in settings.",
              SnackbarType.info);
          await openAppSettings();
          return false;
        }
        return true;
      } else {
        // Android <= 10
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    } else {
      // iOS
      var status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  Future<void> downloadPhoto() async {
    if (images.contains(null)) {
      SSnackbarUtil.showSnackbar(
          "Incomplete",
          "Please capture all 4 photos before downloading.",
          SnackbarType.error);
      return;
    }

    if (!await requestStoragePermission()) {
      SSnackbarUtil.showSnackbar("Permission Denied",
          "Storage permission is required.", SnackbarType.error);
      return;
    }

    final imageBytes = await screenshotController.capture();
    if (imageBytes == null) return;

    final tempDir = Directory.systemTemp;
    final filePath =
        '${tempDir.path}/photo_booth_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await File(filePath).writeAsBytes(imageBytes);

    final success =
        await GallerySaver.saveImage(file.path, albumName: "PhotoBooth");
    if (success == true) {
      SSnackbarUtil.showSnackbar(
          "Saved", "Photo grid saved to gallery", SnackbarType.success);
    } else {
      SSnackbarUtil.showSnackbar(
          "Error", "Failed to save image", SnackbarType.error);
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}

class StickerData {
  String asset;
  double top;
  double left;

  StickerData({required this.asset, required this.top, required this.left});
}
