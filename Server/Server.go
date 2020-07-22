package main

import (
	"fmt"
	"net"
)

var userNum int = 0 // client流水號
var message = make(chan string)
var onlinemap map[string]clientData = make(map[string]clientData)

var chanNum string

type clientData struct {
	name string
	conn net.Conn
}

// server為每個client開一個goroutine來handle
func handleConnection(conn net.Conn) {
	defer conn.Close()

	addr, client := registerNewGuest(conn)

	var haschat = make(chan bool)

	// 開一個goroutine來接收來自client的訊息
	go func() {
		buf := make([]byte, 1024)
		var msg string
		for {
			n, _ := conn.Read(buf)
			// msg = parseInput(string(buf[:n]))
			msg = string(buf[:n])
			if n == 0 { // 離線
				fmt.Printf("%s [%s] 離線\n", client.name, addr)
				delete(onlinemap, addr)
				broadcast(fmt.Sprintf("2 %s 下線囉", client.name), addr)
				return
			}

			// server印出訊息
			fmt.Printf("%s : %s\n", client.name, msg)

			// server 處理訊息
			broadcastIncludeSelf(msg)
			// if strings.HasPrefix(msg, "/setname") { // 設定名稱
			// 	client.name = strings.Split(msg, " ")[1]
			// 	onlinemap[addr] = client
			// 	// 廣播上線訊息
			// 	broadcast(fmt.Sprintf("2 %s 上線囉", client.name), addr)
			// 	privatemsg(fmt.Sprintf("2 %s 您好!", client.name), client.name)
			// } else if strings.HasPrefix(msg, "/rename") { // 改名
			// 	oldName := client.name
			// 	client.name = strings.Split(msg, " ")[1]
			// 	onlinemap[addr] = client
			// 	broadcast(fmt.Sprintf("2 %s 改名為 %s", oldName, client.name), addr)
			// } else if strings.HasPrefix(msg, "/p") { // 密語
			// 	targetUserName := strings.Split(msg, " ")[1]
			// 	privateMsg := strings.SplitN(msg, " ", 3)[2]
			// 	privatemsg(fmt.Sprintf("1 0(p)%s : %s", client.name, privateMsg), targetUserName)
			// 	privatemsg(fmt.Sprintf("0 0(to %s) : %s", targetUserName, privateMsg), client.name)
			// } else { // 一般訊息
			// 	broadcast(fmt.Sprintf("1 %s%s : %s", chanNum, client.name, msg), addr)
			// 	privatemsg(fmt.Sprintf("0 %s%s", chanNum, msg), client.name)
			// }

			haschat <- true
		}
	}()
	for {
		select {
		case <-haschat:
		}
	}
}

// 解析input string
func parseInput(input string) string {
	if input == "" {
		return ""
	}
	chanNum = input[0:1]
	return input[1:]
}

// 新user加入聊天室
func registerNewGuest(conn net.Conn) (string, clientData) {
	addr := conn.RemoteAddr().String()
	client := clientData{"User" + fmt.Sprintf("%d", userNum), conn}
	userNum++
	fmt.Printf("%s [%s] 登入\n", client.name, addr)

	onlinemap[addr] = client

	return addr, client
}

// 廣播
func broadcast(msg string, currentUserAddr string) {
	for addr, client := range onlinemap {
		if addr == currentUserAddr {
			continue // 排除講話的人本身
		}
		client.conn.Write([]byte(msg))
	}
}
func broadcastIncludeSelf(msg string) {
	for _, client := range onlinemap {
		client.conn.Write([]byte(msg))
	}
}

// 密語
func privatemsg(msg string, targetUserName string) {
	for _, client := range onlinemap {
		if client.name == targetUserName {
			client.conn.Write([]byte(msg))
		}
	}
}

func main() {
	// TCP 連線
	listener, _ := net.Listen("tcp", "127.0.0.1:8888")

	for {
		// 有新的client連進來
		conn, _ := listener.Accept()
		// 開一個goroutine來handle這個client
		go handleConnection(conn)
	}
}
