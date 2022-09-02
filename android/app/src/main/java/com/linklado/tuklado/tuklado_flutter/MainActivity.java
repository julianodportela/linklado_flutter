package com.linklado.tuklado.tuklado_flutter;

import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;
import android.view.inputmethod.InputMethodManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.linklado.tuklado.tuklado_flutter/channelTuklado";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = new Intent(
                this, Tuklado.class
        );

        try {
            startService(intent);
        } catch (NullPointerException e) {
            e.printStackTrace();
        }


    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("startSettingsPageLinklado")) {
                                startSettingsPageLinklado();
                            }
                            if (call.method.equals("startInputMethodPageLinklado")) {
                                startInputMethodPageLinklado();
                            }
                        }
                );
    }

    private void startSettingsPageLinklado() {
        startActivityForResult(new Intent(Settings.ACTION_INPUT_METHOD_SETTINGS), 0);
    }

    private void startInputMethodPageLinklado() {
        InputMethodManager imeManager = (InputMethodManager) getApplicationContext().getSystemService(INPUT_METHOD_SERVICE);
        imeManager.showInputMethodPicker();
    }
}
