import 'dart:async';

import 'package:ditto_live_web_alpha/ditto_live_web_alpha.dart';
import 'package:flutter/material.dart';

import 'dialog.dart';
import 'task.dart';
import 'task_view.dart';

// TODO: replace me
const appID = "<replace me with your app id>";
const token = "<replace me with your playground token>";

const collection = "tasks3";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads the WebAssembly binary from the local assets
  await initWasm();

  // For loading the WebAssembly binary from a hosted URL, ensure valid CORS
  // headers and mimetype application/wasm. For local development, you can use a
  // local server like `npx serve ../lib/assets --cors`
  //
  // await initWasm("http://localhost:3000/ditto.wasm");

  final identity = await OnlinePlaygroundIdentity.create(
    appID: appID,
    token: token,
  );

  //
  // DittoLogger
  //

  DittoLogger.setMinimumLogLevel(LogLevel.info);
  DittoLogger.setEmojiLogLevelHeadingsEnabled(true);

  assert(await DittoLogger.getEnabled() == true);
  DittoLogger.setEnabled(false);
  assert(await DittoLogger.getEnabled() == false);
  DittoLogger.setEnabled(true);

  DittoLogger.setCustomLogCallback((level, message) {
    print("[$level] => $message");
  });

  DittoLogger.error("Glad this is not a real error");

  DittoLogger.setCustomLogCallback(null);

  final ditto = await Ditto.open(
    identity: identity,
    persistenceDirectory: "foo",
  );

  await ditto.disableSyncWithV3();
  await ditto.startSync();

  assert(await ditto.smallPeerInfo.getEnabled() == true);
  await ditto.smallPeerInfo.setEnabled(false);
  assert(await ditto.smallPeerInfo.getEnabled() == false);

  assert((await ditto.smallPeerInfo.getMetadata()).isEmpty);
  await ditto.smallPeerInfo.setMetadata({"foo": "bar"});
  print("metadata: ${await ditto.smallPeerInfo.getMetadata()}");

  assert(await ditto.smallPeerInfo.getSyncScope() ==
      SmallPeerInfoSyncScope.bigPeerOnly);
  await ditto.smallPeerInfo.setSyncScope(SmallPeerInfoSyncScope.localPeerOnly);
  assert(await ditto.smallPeerInfo.getSyncScope() ==
      SmallPeerInfoSyncScope.localPeerOnly);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(ditto: ditto),
  ));
}

class MyApp extends StatefulWidget {
  final Ditto ditto;
  const MyApp({super.key, required this.ditto});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  QueryResult? _queryResult;
  var _syncing = true;

  StoreObserver? _storeObserver;
  SyncSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();

    _init();
  }

  Future<void> _init() async {
    _storeObserver = await widget.ditto.store.registerObserver(
      "SELECT * FROM $collection WHERE deleted = false",
      onChange: (qr) => setState(() => _queryResult = qr),
    );

    _storeObserver!.changes.listen((queryResult) {
      print({
        "items": queryResult.items.map((item) => item.value).toList(),
        "mutatedDocumentIDs":
            queryResult.mutatedDocumentIDs.map((id) => id.value).toList(),
      });
    });

    _syncSubscription = await widget.ditto.sync.registerSubscription(
      "SELECT * FROM $collection WHERE deleted = false",
    );
  }

  @override
  void dispose() {
    _storeObserver?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _addTask() async {
    final task = await showAddTaskDialog(context, widget.ditto);
    if (task == null) return;

    await widget.ditto.store.execute(
      "INSERT INTO COLLECTION $collection (${Task.schema}) DOCUMENTS (:task)",
      arguments: {
        "task": task.toJson(),
      },
    );
  }

  Future<void> _clearTasks() async {
    await widget.ditto.store.execute(
      "EVICT FROM COLLECTION $collection (${Task.schema}) WHERE true",
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Ditto Tasks"),
          actions: [
            IconButton(
              onPressed: _clearTasks,
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addTask,
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: ListView(
            children: [
              _syncTile,
              ...?_queryResult?.items.map(
                (item) => TaskView(
                  ditto: widget.ditto,
                  task: Task.fromJson(item.value),
                ),
              ),
            ],
          ),
        ),
      );

  Widget get _syncTile => SwitchListTile(
        title: const Text("Syncing"),
        value: _syncing,
        onChanged: (value) async {
          if (value) {
            await widget.ditto.startSync();
          } else {
            await widget.ditto.stopSync();
          }

          setState(() => _syncing = value);
        },
      );
}
