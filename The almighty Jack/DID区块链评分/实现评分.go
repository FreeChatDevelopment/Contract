package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

type UserBlockchainData struct {
	Address string
	Assets  map[string]AssetInfo
	Title   string
}

type AssetInfo struct {
	Amount    float64
	Transfers float64
}

type BlockchainAPIResponse struct {
	Data map[string]AssetInfo `json:"data"`
}

func main() {
	userAddress := "0x1234567890abcdef"
	userData, err := getUserBlockchainData(userAddress)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Printf("User address: %s\n", userData.Address)
	fmt.Println("User assets and transfers:")
	for asset, info := range userData.Assets {
		fmt.Printf("%s: Amount: %.2f Transfers: %.2f\n", asset, info.Amount, info.Transfers)
	}
	fmt.Printf("User title: %s\n", userData.Title)
}

func getUserBlockchainData(address string) (*UserBlockchainData, error) {
	assets, err := queryUserAssets(address)
	if err != nil {
		return nil, err
	}

	title := calculateTitle(assets)

	return &UserBlockchainData{
		Address: address,
		Assets:  assets,
		Title:   title,
	}, nil
}

func queryUserAssets(address string) (map[string]AssetInfo, error) {
	apiUrl := "https://blockchain-api.example.com/user_assets?address=" + address
	resp, err := http.Get(apiUrl)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var apiResponse BlockchainAPIResponse
	err = json.Unmarshal(body, &apiResponse)
	if err != nil {
		return nil, err
	}

	return apiResponse.Data, nil
}

func calculateTitle(assets map[string]AssetInfo) string {
	totalValue := 0.0
	totalTransfers := 0.0

	for _, info := range assets {
		totalValue += info.Amount
		totalTransfers += info.Transfers
	}

	total := totalValue + totalTransfers

	switch {
	case total == 0:
		return "初学者"
	case total >= 1000 && total < 10000:
		return "青铜"
	case total >= 10000 && total < 100000:
		return "白银"
	case total >= 100000 && total < 500000:
		return "黄金"
	case total >= 500000 && total < 1000000:
		return "白金"
	case total >= 1000000 && total < 5000000:
		return "钻石"
	case total >= 5000000 && total < 10000000:
		return "黑金"
case total >= 10000000 && total < 20000000:
	return "星耀"
case total >= 20000000 && total < 50000000:
	return "王者"
case total >= 50000000 && total < 100000000:
	return "最强王者"
default:
	return "未知"
}
}

