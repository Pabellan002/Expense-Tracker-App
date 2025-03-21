package me.carda.awesome_notifications;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

// This is a simplified implementation to satisfy the dependency
public class AwesomeNotificationsPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    @Override
    public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
        // Empty implementation
    }

    @Override
    public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
        // Empty implementation
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        // Empty implementation
        result.notImplemented();
    }
} 