package main

import (
	"database/sql"
	"errors"
	"fmt"

	_ "github.com/go-sql-driver/mysql"
)

const maxRedPacketQuantity = 10000

type RedPacket struct {
	ID          int
	TotalAmount float64
	Quantity    int
}

func main() {
	db, err := sql.Open("mysql", "username:password@tcp(127.0.0.1:3306)/dbname")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	// Example: Create a red packet
	redPacket := RedPacket{ID: 1, TotalAmount: 500, Quantity: 10}
	err = createRedPacket(db, &redPacket)
	if err != nil {
		fmt.Println("Error creating red packet:", err)
		return
	}

	// Example: Grab a red packet for user 1
	err = grabRedPacket(db, &redPacket, 1)
	if err != nil {
		fmt.Println("Error grabbing red packet:", err)
		return
	}
}

func createRedPacket(db *sql.DB, redPacket *RedPacket) error {
	if redPacket.Quantity > maxRedPacketQuantity {
		return errors.New("red packet quantity exceeds the limit")
	}
	if redPacket.TotalAmount <= 0 || redPacket.Quantity <= 0 {
		return errors.New("total amount and quantity must be greater than 0")
	}
	return nil
}

func grabRedPacket(db *sql.DB, redPacket *RedPacket, userID int) error {
	if redPacket.Quantity <= 0 {
		return errors.New("no red packets left")
	}

	// Check if user has already grabbed the red packet
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM User_redPacket_ID WHERE redPacket_ID = ? AND user_id = ?", redPacket.ID, userID).Scan(&count)
	if err != nil {
		return errors.New("error checking if user has grabbed the red packet")
	}
	if count > 0 {
		return errors.New("user has already grabbed the red packet")
	}

	amountPerPacket := redPacket.TotalAmount / float64(redPacket.Quantity)
	_, err = db.Exec("UPDATE user_balance SET balance = balance + ? WHERE user_id = ?", amountPerPacket, userID)
	if err != nil {
		return errors.New("error updating user balance")
	}

	// Record the user grabbed the red packet
	_, err = db.Exec("INSERT INTO User_redPacket_ID (redPacket_ID, user_id) VALUES (?, ?)", redPacket.ID, userID)
	if err != nil {
		return errors.New("error recording grabbed red packet")
	}

	redPacket.Quantity--
	redPacket.TotalAmount -= amountPerPacket

	return nil
}
