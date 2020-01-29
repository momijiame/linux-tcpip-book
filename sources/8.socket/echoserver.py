#!/usr/bin/env python3

"""ソケットを使ってエコーサーバを実装したスクリプト"""

import socket


def send_msg(sock, msg):
    """ソケットに指定したバイト列を書き込む関数"""
    # これまでに送信できたバイト数
    total_sent_len = 0
    # 送信したいバイト数
    total_msg_len = len(msg)
    # まだ送信したいデータが残っているか判定する
    while total_sent_len < total_msg_len:
        # ソケットにバイト列を書き込んで、書き込めたバイト数を得る
        sent_len = sock.send(msg[total_sent_len:])
        # まったく書き込めなかったらソケットの接続が終了している
        if sent_len == 0:
            raise RuntimeError('socket connection broken')
        # 書き込めた分を加算する
        total_sent_len += sent_len


def recv_msg(sock, chunk_len=1024):
    """ソケットから接続が終わるまでバイト列を読み込むジェネレータ関数"""
    while True:
        # ソケットから指定したバイト数を読み込む
        received_chunk = sock.recv(chunk_len)
        # まったく読めなかったときは接続が終了している
        if len(received_chunk) == 0:
            break
        # 受信したバイト列を返す
        yield received_chunk


def main():
    """スクリプトとして実行されたときに呼び出されるメイン関数"""
    # IPv4 / TCP で通信するソケットを用意する
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # 'Address already in use' の回避策
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    # クライアントから接続を待ち受ける IP アドレスとポート番号を指定する
    server_socket.bind(('127.0.0.1', 54321))
    # 接続の待ち受けを開始する
    server_socket.listen()
    # サーバが動作を開始したことを表示する
    print('starting server ...')
    # 接続を処理する
    client_socket, (client_address, client_port) = server_socket.accept()
    # 接続してきたクライアントの情報を表示する
    print(f'accepted from {client_address}:{client_port}')
    # ソケットからバイト列を読み込む
    for received_msg in recv_msg(client_socket):
        # 読み込んだ内容をそのままソケットに書き込む (エコーバック)
        send_msg(client_socket, received_msg)
        # 送受信した内容を出力しておく
        print(f'echo: {received_msg}')
    # 使い終わったソケットをクローズする
    client_socket.close()
    server_socket.close()


if __name__ == '__main__':
    """スクリプトのエントリーポイントとしてメイン関数を実行する"""
    main()
