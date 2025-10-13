import 'dart:io';
import 'dart:ui';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:photoboothapp/ad_helper.dart';
import 'package:photoboothapp/pages/snackbar.dart';
import 'package:screenshot/screenshot.dart';
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
  late BannerAd bannerAd;
  late InterstitialAd interstitialAd;
  @override
  void onInit() {
    super.onInit();
    _loadBannerAd();
    loadInterAd();
    initCamera();
  }

  var isBannerLoaded = false.obs;
  var isinterLoaded = false.obs;

  void _loadBannerAd() {
    final ad = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          bannerAd = ad as BannerAd;
          isBannerLoaded.value = true; // ✅ triggers UI update
          print("Banner Ad Loaded");
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  void loadInterAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.bannerInterstatialUnitId, // your interstitial unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          isinterLoaded.value = true;
          print("Interstitial Ad Loaded");
        },
        onAdFailedToLoad: (err) {
          print("Failed to load interstitial ad: ${err.message}");
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!isinterLoaded.value) return;

    interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isinterLoaded.value = false;
        loadInterAd(); // reload for next time
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isinterLoaded.value = false;
        loadInterAd();
      },
    );

    interstitialAd.show();
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
        !cameraController!.value.isInitialized)
      return;

    isProcessing.value = true;

    try {
      for (int slot = 0; slot < images.length; slot++) {
        activeSlot.value = slot; // activate current grid
        images.refresh(); // force UI update
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // small delay for UI to catch up

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
      stickers.add(
        StickerData(
          asset: selectedSticker.value,
          top: position?.dy ?? 150,
          left: position?.dx ?? 100,
        ),
      );
    }
  }

  void undoSticker() {
    if (stickerHistory.isNotEmpty) {
      stickers.value = stickerHistory.removeLast();
    }
  }

  void _saveStickerHistory() {
    stickerHistory.add(
      stickers
          .map((s) => StickerData(asset: s.asset, top: s.top, left: s.left))
          .toList(),
    );
  }

  void updateStickerPosition(int index, double top, double left) {
    stickers[index].top = top;
    stickers[index].left = left;
    stickers.refresh();
  }

  void clearAll() {
    images.value = [null, null, null, null];
    activeSlot.value = 0;
    stickers.clear();
    stickerHistory.clear();
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
            SnackbarType.info,
          );
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
        SnackbarType.error,
      );
      return;
    }

    if (!await requestStoragePermission()) {
      SSnackbarUtil.showSnackbar(
        "Permission Denied",
        "Storage permission is required.",
        SnackbarType.error,
      );
      return;
    }

    final imageBytes = await screenshotController.capture();
    if (imageBytes == null) return;

    final tempDir = Directory.systemTemp;
    final filePath =
        '${tempDir.path}/photo_booth_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await File(filePath).writeAsBytes(imageBytes);

    final success = await GallerySaver.saveImage(
      file.path,
      albumName: "PhotoBooth",
    );

    if (success == true) {
      SSnackbarUtil.showSnackbar(
        "Saved",
        "Photo grid saved to gallery",
        SnackbarType.success,
      );
    } else {
      SSnackbarUtil.showSnackbar(
        "Error",
        "Failed to save image",
        SnackbarType.error,
      );
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    interstitialAd.dispose();
    bannerAd.dispose();
    super.onClose();
  }
}

class StickerData {
  String asset;
  double top;
  double left;

  StickerData({required this.asset, required this.top, required this.left});
}
