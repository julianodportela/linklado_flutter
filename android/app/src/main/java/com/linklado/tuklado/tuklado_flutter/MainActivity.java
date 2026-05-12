package com.linklado.tuklado.tuklado_flutter;

import android.content.Intent;
import android.provider.Settings;
import android.view.inputmethod.InputMethodInfo;
import android.view.inputmethod.InputMethodManager;

import androidx.annotation.NonNull;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.linklado.tuklado.tuklado_flutter/channelLinklado";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startSettingsPageLinklado":
                            startActivity(new Intent(Settings.ACTION_INPUT_METHOD_SETTINGS));
                            result.success(null);
                            break;
                        case "startInputMethodPageLinklado":
                            InputMethodManager imm =
                                    (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
                            imm.showInputMethodPicker();
                            result.success(null);
                            break;
                        case "isLinkladoEnabled":
                            result.success(isLinkladoEnabled());
                            break;
                        case "isLinkladoActive":
                            result.success(isLinkladoActive());
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    // Returns true if Linklado appears in the user's enabled input methods list.
    private boolean isLinkladoEnabled() {
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        List<InputMethodInfo> enabled = imm.getEnabledInputMethodList();
        for (InputMethodInfo imi : enabled) {
            if (imi.getPackageName().equals(getPackageName())) return true;
        }
        return false;
    }

    // Returns true if Linklado is the currently selected default input method.
    private boolean isLinkladoActive() {
        String current = Settings.Secure.getString(
                getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD);
        return current != null && current.startsWith(getPackageName() + "/");
    }
}
