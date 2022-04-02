```
cd docker
docker build -t linux-tcpip-book .
docker run -it --rm -v $(pwd)/work:/work linux-tcpip-book bash
```

Googleが運用する高階DNSサーバのIPアドレス
- `8.8.8.8`

tcpdump コマンド例
- `tcpdump -tn -i any icmp`
- t: 時刻に関する情報を出力しない
- n: IPアドレスを逆引きせずそのまま表示
- i: パケットキャプチャする対象のネットワークインターフェイスを指定
  - any を指定するtお全てのネットワークインターフェイスが対象になる
- icmp: キャプチャ対象をICMPに限定

