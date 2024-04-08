package com.example.lan_scan.runnable;

import android.util.Log;

import java.io.IOException;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;

public class ScanHostsRunnable implements Runnable {

    private final String tag = ScanHostsRunnable.class.getSimpleName();
    private final int start;
    private final int stop;
    private final Long timeout;

    /**
     * Constructor to set the necessary data to scan for hosts
     *
     * @param start   Host to start scanning at
     * @param stop    Host to stop scanning at
     * @param timeout Socket timeout
     */
    public ScanHostsRunnable(int start, int stop, Long timeout) {
        this.start = start;
        this.stop = stop;
        this.timeout = timeout;
    }

    /**
     * Starts the host discovery
     */
    @Override
    public void run() {

        for (int i = start; i <= stop; i++) {

            try (Socket socket = new Socket()) {
                socket.setTcpNoDelay(true);
                byte[] bytes = BigInteger.valueOf(i).toByteArray();
                InetAddress addr = InetAddress.getByAddress(bytes);
                Log.d(tag, "ip:" + addr.getHostAddress());
                socket.connect(new InetSocketAddress(addr, 7), Math.toIntExact(timeout));

            } catch (IOException ignored) {
                // Connection failures aren't errors in this case.
                // We want to fill up the ARP table with our connection attempts.
            }
        }
    }
}