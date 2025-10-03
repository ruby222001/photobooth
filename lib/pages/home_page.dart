import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photoboothapp_new/controller/controller.dart';
import 'package:photoboothapp_new/pages/sticker_data.dart';
import 'package:screenshot/screenshot.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PhotoController controller = Get.put(PhotoController());
    final List<String> stickers = [
      "assets/milk.png",
      "assets/cherry.png",
      "assets/cat.png",
      "assets/heart-shape (1).png",
      "assets/heart-shape.png",

      "assets/milk.png",
      "assets/pineapple.png",
      "assets/snail.png",
      "assets/strawberry.png",
      "assets/xoxo.png",
      "assets/milk.png",
      "assets/cherry.png",
      "assets/cat.png",
      "assets/heart-shape (1).png",
      "assets/heart-shape.png",

      "assets/milk.png",
      "assets/pineapple.png",
      "assets/snail.png",
      "assets/strawberry.png",
      "assets/xoxo.png",

      // Add more sticker paths here
    ];
    return Scaffold(
        backgroundColor: Colors.pink[50],
        appBar: AppBar(
          backgroundColor: Colors.pink[100],
          title: const Text(
            "Photo Booth",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),

        // Bottom Bar (Row of Reset, Undo, Download + Camera Buttons)
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Reset / Undo / Download Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BottomActionButton(
                  icon: Icons.replay,
                  color: Colors.pink.shade400,
                  onTap: () => controller.clearAll(),
                ),
                BottomActionButton(
                  icon: Icons.undo,
                  color: Colors.pink.shade400,
                  onTap: () => controller.undoSticker(),
                ),
                BottomActionButton(
                  icon: Icons.downloading_sharp,
                  color: Colors.pink.shade400,
                  onTap: () async => await controller.downloadPhoto(),
                ),
                BottomActionButton(
                  icon: Icons.switch_camera_outlined,
                  color: Colors.pink.shade400,
                  onTap: () async => await controller.switchCamera(),
                ),
                BottomActionButton(
                  icon: Icons.camera_alt_outlined,
                  color: Colors.pink.shade400,
                  onTap: () async => await controller.takePhotoSequence(),
                ),
              ],
            ),
          ]),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 30,
              ), // Photo grid

              const SizedBox(height: 20),
              Obx(() => Screenshot(
                  controller: controller.screenshotController,
                  child: Container(
                    height: 450,
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pink, width: 2),
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        if (controller.images.every((img) => img != null)) {
                          final localPosition = details.localPosition;
                          controller.addSticker(position: localPosition);
                        }
                      },
                      child: Stack(
                        children: [
                          // Grid photos
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.images.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemBuilder: (context, index) {
                              final image = controller.images[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.pink),
                                  ),
                                  child: image != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(image,
                                              fit: BoxFit.cover),
                                        )
                                      : Center(
                                          child: Image.asset("assets/add.jpg")),
                                ),
                              );
                            },
                          ),

                          // Stickers
                          ...controller.stickers.asMap().entries.map((entry) {
                            int index = entry.key;
                            StickerData sticker = entry.value;
                            return Positioned(
                              top: sticker.top,
                              left: sticker.left,
                              child: Draggable<int>(
                                data: index,
                                feedback: Image.asset(sticker.asset,
                                    width: 60, height: 60),
                                childWhenDragging: Container(),
                                onDragEnd: (details) {
                                  final localOffset = details.offset -
                                      Offset(16, 16); // padding
                                  controller.updateStickerPosition(
                                    index,
                                    localOffset.dy.clamp(0.0, 390 - 60),
                                    localOffset.dx.clamp(0.0,
                                        MediaQuery.of(context).size.width - 60),
                                  );
                                },
                                child: Image.asset(sticker.asset,
                                    width: 60, height: 60),
                              ),
                            );
                          }).toList(),

                          // Countdown in the middle
                          Obx(() {
                            if (controller.countdown.value > 0) {
                              return Positioned.fill(
                                child: Center(
                                  child: Text(
                                    "${controller.countdown.value}",
                                    style: const TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                    ),
                  ))),

              const SizedBox(height: 20),

              Text(
                'Stickers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(
                height: 5,
              ),
              Wrap(
                spacing: 14, // horizontal space between stickers
                runSpacing: 10, // vertical space between rows
                alignment: WrapAlignment.center,
                children: stickers.map((stickerPath) {
                  return GestureDetector(
                    onTap: () => controller.selectedSticker.value = stickerPath,
                    child: Container(
                      padding: const EdgeInsets.all(4), // optional padding
                      decoration: BoxDecoration(
                        color: Colors.white, // background for each sticker
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.pink.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(stickerPath, width: 40, height: 40),
                    ),
                  );
                }).toList(),
              ),

              // Countdown timer (big below grid)
            ]),
          ),
        ));
  }
}
