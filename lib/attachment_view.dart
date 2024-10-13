// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
//
// class AttachmentView extends StatefulWidget {
//   final Ditto ditto;
//   final Map<String, dynamic> attachmentToken;
//
//   const AttachmentView({
//     super.key,
//     required this.ditto,
//     required this.attachmentToken,
//   });
//
//   @override
//   State<AttachmentView> createState() => _AttachmentViewState();
// }
//
// class _AttachmentViewState extends State<AttachmentView> {
//   Uint8List? _bytes;
//   double _progress = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   Future<void> _init() async {
//     await widget.ditto.store.fetchAttachment(
//       widget.attachmentToken,
//       (event) {
//         print(event);
//         return switch (event) {
//           AttachmentFetchEventProgress progress => setState(() {
//               _progress = progress.downloadedBytes / progress.totalBytes;
//             }),
//           AttachmentFetchEventCompleted completed =>
//             _complete(completed.attachment),
//           AttachmentFetchEventDeleted _ => print("deleted"),
//         };
//       },
//     );
//   }
//
//   Future<void> _complete(Attachment attachment) async {
//     final bytes = await attachment.data();
//     setState(() => _bytes = bytes);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bytes = _bytes;
//
//     if (bytes == null) return CircularProgressIndicator(value: _progress);
//     return Image.memory(bytes);
//   }
// }
