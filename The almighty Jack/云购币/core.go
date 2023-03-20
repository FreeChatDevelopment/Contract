package main

import (
	"fmt"
	"math/rand"
	"time"
)

// 定义商品结构体
type Product struct {
	Name  string // 商品名称
	Price int    // 商品价格
	Parts []int  // 商品份数
}

// 定义用户结构体
type User struct {
	ID       int   // 用户ID
	Purchased []int // 用户购买的号码
}

// 创建商品的函数
func createProduct(name string, price int) *Product {
	p := &Product{Name: name, Price: price}
	p.Parts = make([]int, price)

	for i := 0; i < price; i++ {
		p.Parts[i] = i + 1
	}

	return p
}

// 用户购买商品的函数
func purchase(user *User, product *Product, num int) {
	if len(product.Parts) < num {
		num = len(product.Parts)
	}

	for i := 0; i < num; i++ {
		part := rand.Intn(len(product.Parts))
		user.Purchased = append(user.Purchased, product.Parts[part])
		product.Parts = append(product.Parts[:part], product.Parts[part+1:]...)
	}
}

// 寻找获奖者的函数
func findWinner(users []*User, randomNumber int) *User {
	totalParts := 0
	for _, user := range users {
		totalParts += len(user.Purchased)
	}
	if totalParts == 0 {
		return nil
	}

	winningPartIndex := randomNumber % totalParts
	currentIndex := 0

	for _, user := range users {
		for _, part := range user.Purchased {
			if currentIndex == winningPartIndex {
				return user
			}
			currentIndex++
		}
	}

	return nil
}

func main() {
	rand.Seed(time.Now().UnixNano())

	// 创建商品
	product := createProduct("iPhone 13", 30000)

	// 创建用户并购买号码
	user1 := &User{ID: 1}
	purchase(user1, product, 5000)

	user2 := &User{ID: 2}
	purchase(user2, product, 10000)

	user3 := &User{ID: 3}
	purchase(user3, product, 15000)

	// 确保所有号码都被购买
	user4 := &User{ID: 4}
	purchase(user4, product, len(product.Parts))

	// 从外部获取随机数，这里用随机数模拟
	randomNumber := rand.Intn(30000)
	// 寻找获奖者
	winner := findWinner([]*User{user1, user2, user3, user4}, randomNumber)

		// 输出获奖者信息
		if winner != nil {
			fmt.Printf("中奖用户ID: %d\n", winner.ID)
		} else {
			fmt.Println("无中奖用户")
		}
	}
	

