import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncora_frontend/core/analytics/breadcrumb.dart';
import 'package:syncora_frontend/core/analytics/breadcrumbs_service.dart';

/// Widget that displays the list of breadcrumbs for debugging
class BreadcrumbLog extends StatefulWidget {
  const BreadcrumbLog({super.key});

  @override
  State<BreadcrumbLog> createState() => _BreadcrumbLogState();
}

class _BreadcrumbLogState extends State<BreadcrumbLog> {
  final _controller = ScrollController();

  bool folded = false;

  List<Breadcrumb> crumbs = List.empty(growable: true);

  bool skipAdd = false;

  @override
  Widget build(BuildContext context) {
    double width = (MediaQuery.sizeOf(context).width / 1.2).clamp(100, 500);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      width: width,
      height: folded ? 10 : 200,
      top: 0,
      left: 0,
      child: Opacity(
        opacity: 1,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        skipAdd = true;
                        folded = !folded;
                      });
                    },
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(10),
                      color: Colors.amber.withValues(alpha: 0.8),
                      child: StreamBuilder(
                        stream: BreadcrumbService.instance.crumbStream,
                        builder: (context, snapshot) {
                          if (_controller.hasClients) {
                            if (snapshot.data != null && !skipAdd) {
                              crumbs.add(snapshot.data!);
                            }

                            Future.microtask(
                              () {
                                _controller.jumpTo(
                                    _controller.position.maxScrollExtent);
                                skipAdd = false;
                              },
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            controller: _controller,
                            itemCount: crumbs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                  "${crumbs[index].sinceLastCrumbMilliseconds / 1000}s | ${crumbs[index].type.name}: ${crumbs[index].context}");
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      skipAdd = true;
                      crumbs.clear();
                    });
                  },
                  icon: Icon(
                    Icons.clear_all_outlined,
                    color: folded ? Colors.transparent : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
