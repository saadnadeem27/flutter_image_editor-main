import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_editor_example/const/resource.dart';
// import 'package:flutter_image_editor_example/extended_pkg/src/editor/editor.dart';
// import 'package:flutter_image_editor_example/extended_pkg/src/editor/editor_utils.dart';
// import 'package:flutter_image_editor_example/extended_pkg/src/extended_image.dart';
// import 'package:flutter_image_editor_example/extended_pkg/src/utils.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oktoast/oktoast.dart';

class ExtendedImageExample extends StatefulWidget {
  @override
  _ExtendedImageExampleState createState() => _ExtendedImageExampleState();
}

class _ExtendedImageExampleState extends State<ExtendedImageExample> {
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();
  bool isCropTapped = false;
  List<double> cropRatios = [
    CropAspectRatios.ratio16_9,
    CropAspectRatios.ratio1_1,
    CropAspectRatios.ratio9_16,
    CropAspectRatios.ratio4_3
  ];
  double cRatio = CropAspectRatios.ratio16_9;
  ImageProvider provider = ExtendedExactAssetImageProvider(
    R.ASSETS_HAVE_EXIF_3_JPG,
    cacheRawData: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Use extended_image library'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _pick,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              await crop();
            },
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: buildImage(),
            ),
            if (isCropTapped)
              Container(
                height: 50,
                width: 200,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: cropRatios.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            cRatio = cropRatios[index];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text('1:1'),
                        ),
                      );
                    }),
              )
          ],
        ),
      ),
      bottomNavigationBar: _buildFunctions(),
    );
  }

  Widget buildImage() {
    return ExtendedImage(
      image: provider,
      height: 400,
      width: 400,
      extendedImageEditorKey: editorKey,
      mode: ExtendedImageMode.editor,
      fit: BoxFit.contain,
      initEditorConfigHandler: (_) => EditorConfig(
        maxScale: 8.0,
        cropRectPadding: const EdgeInsets.all(20.0),
        hitTestSize: 20.0,
        cropAspectRatio: cRatio,
      ),
    );
  }

  Widget _buildFunctions() {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.crop),
          label: 'Crop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.flip),
          label: 'Flip',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rotate_left),
          label: 'Rotate left',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rotate_right),
          label: 'Rotate right',
        ),
      ],
      onTap: (int index) {
        switch (index) {
          case 0:
            cropList();
            break;
          case 1:
            flip();
            break;
          case 2:
            rotate(false);
            break;
          case 3:
            rotate(true);
            break;
        }
      },
      currentIndex: 0,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> crop([bool test = false]) async {
    final ExtendedImageEditorState? state = editorKey.currentState;
    if (state == null) {
      return;
    }
    final Rect? rect = state.getCropRect();
    if (rect == null) {
      showToast('The crop rect is null.');
      return;
    }
    final EditActionDetails action = state.editAction!;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    // final img = await getImageFromEditorKey(editorKey);
    final Uint8List? img = state.rawImageData;

    if (img == null) {
      showToast('The img is null.');
      return;
    }

    final ImageEditorOption option = ImageEditorOption();
    print('horizontal : $flipHorizontal');
    print('vertical : $flipVertical');

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.outputFormat = const OutputFormat.png(88);

    print(const JsonEncoder.withIndent('  ').convert(option.toJson()));

    // final DateTime start = DateTime.now();
    final Uint8List? result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    print('result.length = ${result?.length}');

    // final Duration diff = DateTime.now().difference(start);

    // print('image_editor time : $diff');
    // showToast('handle duration: $diff',
    //     duration: const Duration(seconds: 5), dismissOtherToast: true);

    if (result == null) return;

    showPreviewDialog(result);
    var isSaved = await ImageGallerySaver.saveImage(result);
    if (isSaved != null) {
      showToast('Image saved to gallery');
    } else {
      showToast('Image not saved');
    }
  }

  void horizontalflip() {
    editorKey.currentState?.flip();
  }

  void flip() {
    editorKey.currentState?.flip();
  }

  void cropList() {
    setState(() {
      isCropTapped = !isCropTapped;
    });
  }

  void rotate(bool right) {
    editorKey.currentState?.rotate(right: right);
  }

  void showPreviewDialog(Uint8List image) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.grey.withOpacity(0.5),
          child: Center(
            child: SizedBox.fromSize(
              size: const Size.square(200),
              child: Container(
                child: Image.memory(image),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final XFile? result = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (result == null) {
      showToast('The pick file is null');
      return;
    }
    print(result.path);
    provider = ExtendedFileImageProvider(File(result.path), cacheRawData: true);
    setState(() {});
  }
}
