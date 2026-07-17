package com.example.pos_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * One-shot classic Bluetooth SPP print path for ESC/POS thermal printers.
 * Avoids the third-party plugin's fragile connect/status/send state machine.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.pos_app/classic_bt_printer"
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "printRaw" -> {
                        val address = call.argument<String>("address")?.trim().orEmpty()
                        val bytes = coerceBytes(call.argument("bytes"))
                        if (address.isEmpty()) {
                            result.error("bad_args", "缺少藍牙位址", null)
                            return@setMethodCallHandler
                        }
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("bad_args", "列印資料為空", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                printRawSync(address, bytes)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                Log.e(TAG, "classic BT print failed", e)
                                runOnUiThread {
                                    result.error(
                                        "print_failed",
                                        e.message ?: e.javaClass.simpleName,
                                        null,
                                    )
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun coerceBytes(raw: Any?): ByteArray? {
        return when (raw) {
            null -> null
            is ByteArray -> raw
            is ArrayList<*> -> ByteArray(raw.size) { i ->
                when (val v = raw[i]) {
                    is Number -> v.toByte()
                    else -> 0
                }
            }
            is List<*> -> ByteArray(raw.size) { i ->
                when (val v = raw[i]) {
                    is Number -> v.toByte()
                    else -> 0
                }
            }
            else -> null
        }
    }

    private fun adapter(): BluetoothAdapter {
        val mgr = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        return mgr.adapter
            ?: throw IOException("此裝置不支援藍牙")
    }

    private fun printRawSync(address: String, bytes: ByteArray) {
        val adapter = adapter()
        if (!adapter.isEnabled) {
            throw IOException("請先開啟手機藍牙")
        }

        try {
            adapter.cancelDiscovery()
        } catch (_: SecurityException) {
        }

        val device = try {
            adapter.getRemoteDevice(address.uppercase())
        } catch (e: IllegalArgumentException) {
            throw IOException("藍牙位址無效：$address")
        }

        val socket = connectWithFallback(device)
        try {
            val out = socket.outputStream
                ?: throw IOException("無法取得藍牙輸出串流")
            var offset = 0
            val chunk = 512
            while (offset < bytes.size) {
                val len = minOf(chunk, bytes.size - offset)
                out.write(bytes, offset, len)
                out.flush()
                offset += len
                if (offset < bytes.size) {
                    Thread.sleep(20)
                }
            }
            // Give the printer time to drain before closing SPP.
            val drainMs = (400 + bytes.size / 40).coerceIn(400, 2500)
            Thread.sleep(drainMs.toLong())
        } finally {
            try {
                socket.close()
            } catch (_: IOException) {
            }
        }
    }

    private fun connectWithFallback(device: BluetoothDevice): BluetoothSocket {
        val attempts = listOf(
            "insecure_spp" to {
                device.createInsecureRfcommSocketToServiceRecord(sppUuid)
            },
            "secure_spp" to {
                device.createRfcommSocketToServiceRecord(sppUuid)
            },
            "reflect_channel_1" to {
                val m = device.javaClass.getMethod(
                    "createRfcommSocket",
                    Int::class.javaPrimitiveType ?: Integer.TYPE,
                )
                m.invoke(device, 1) as BluetoothSocket
            },
            "reflect_insecure_channel_1" to {
                val m = device.javaClass.getMethod(
                    "createInsecureRfcommSocket",
                    Int::class.javaPrimitiveType ?: Integer.TYPE,
                )
                m.invoke(device, 1) as BluetoothSocket
            },
        )

        val errors = mutableListOf<String>()
        for ((label, factory) in attempts) {
            var socket: BluetoothSocket? = null
            try {
                socket = factory()
                Log.i(TAG, "BT connect attempt $label → ${device.address}")
                socket.connect()
                Log.i(TAG, "BT connect OK via $label")
                return socket
            } catch (e: Exception) {
                val msg = e.message ?: e.javaClass.simpleName
                Log.w(TAG, "BT connect failed ($label): $msg")
                errors.add("$label: $msg")
                try {
                    socket?.close()
                } catch (_: IOException) {
                }
            }
        }

        val bondedHint = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            try {
                if (device.bondState != BluetoothDevice.BOND_BONDED) {
                    "；且尚未在系統設定完成配對"
                } else {
                    ""
                }
            } catch (_: SecurityException) {
                ""
            }
        } else {
            ""
        }

        throw IOException(
            "無法連線 ${device.address}$bondedHint（${errors.joinToString(" | ")}）",
        )
    }

    companion object {
        private const val TAG = "ClassicBtPrinter"
    }
}
