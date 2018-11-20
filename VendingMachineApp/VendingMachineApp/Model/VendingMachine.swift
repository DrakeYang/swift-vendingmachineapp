//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Yoda Codd on 2018. 7. 26..
//  Copyright © 2018년 JK. All rights reserved.
//

import Foundation
/// 자판기의 기본적인 메뉴
protocol vendinMachineMenu {
    func getMoney()->Int
    func getAllAvailableDrinks()->InventoryDetail
    func addDrink(drink:Drink)throws->StoredDrinkDetail?
}
/// 사용자용 메뉴
protocol VendingMachineUserMenu : vendinMachineMenu {
    //    func getUserMainMenu(menu:InputView.UserFirstMenu,orderDetail:OrderDetail,drinkPrice:Int)throws->String
}
/// 관리자용 메뉴
protocol VendingMachineAdminMenu : vendinMachineMenu {
    //    func getAdminMainMenu(menu:InputView.AdminFirstMenu,orderDetail:OrderDetail)throws->String
}

class VendingMachine : vendinMachineMenu  {
    /// 자판기에 들어있는 금액
    private var insertedMoney = 0
    
    /// 재고창고
    private var drinkInventory : DrinkInventory
    
    /// 주문한 음료수가 쌓이는 곳
    private var orderedDrinks = DrinkInventory()
    
    /// 생성자
    init(){
        drinkInventory = DrinkInventory()
    }
    
    /// 디코더
    required init?(coder aDecoder: NSCoder) {
        self.insertedMoney = aDecoder.decodeInteger(forKey: "insertedMoney")
        self.drinkInventory = aDecoder.decodeObject(forKey: "drinkInventory") as! DrinkInventory
        self.orderedDrinks = aDecoder.decodeObject(forKey: "orderedDrinks") as! DrinkInventory
    }

    /// 인코더
    func encode(with aCoder: NSCoder) {
        aCoder.encode(insertedMoney, forKey: "insertedMoney")
        aCoder.encode(drinkInventory, forKey: "drinkInventory")
        aCoder.encode(orderedDrinks, forKey: "orderedDrinks")
    }
    
    /// 금액 추가 함수
    func plusMoney(money:Int)->String{
        self.insertedMoney += money
        return "\(money)원을 추가하였습니다."
    }
    
    /// 금액 사용 함수
    func minusMoney(money:Int)throws{
        let resultMoney = self.insertedMoney - money
        if resultMoney < 0 {
            throw OutputView.errorMessage.notEnoughMoney
        }
        self.insertedMoney = resultMoney
    }
    
    /// 금액 출력 함수
    func getMoney()->Int{
        return self.insertedMoney
    }
    
    /// 주문한 음료수 전체 내용 리턴
    func getAllOrderdDrink()->String{
        return orderedDrinks.getTotalDrinkDetail().getAllDrinkDetails()
    }
    
    /// 재고 추가
    func addDrink(drink:Drink)throws->StoredDrinkDetail?{
        let result = try self.drinkInventory.addDrink(undefinedDrink: drink)
        return result
    }
    
    /// 남아있는 모든 재고 확인
    func getAllAvailableDrinks()->InventoryDetail{
        return drinkInventory.getTotalDrinkDetail()
    }
    
    
    /// 원하는 음료의 가격을 잔액과 배교한다
    func isEnoughMoney(storedDrinkDetail:StoredDrinkDetail,orderDrinkCount:Int)throws->Int{
        // 총 주문금액 변수
        let totalOrderPrice = orderDrinkCount * storedDrinkDetail.drinkPrice
        // 입력된금액 < 주문금액 이면 에러
        if self.getMoney() < totalOrderPrice {
            throw OutputView.errorMessage.notEnoughMoney
        }
        return totalOrderPrice
    }
    
}

extension VendingMachine : VendingMachineUserMenu {
    /// 음료주문 기능
    func orderDrinks(orderDetail:OrderDetail)throws->StoredDrinkDetail{
        // 음료타입과 개수를 받아서 해당 음료를 재고에서 빼낸다
        let movedDrinks = try drinkInventory.popDrinks(orderDetail: orderDetail)
        // 이동된 음료를 주문리스트에 넣고 옮겨진 음료정보를 기록한다
        let movedDrinksDetail : StoredDrinkDetail = try self.orderedDrinks.addDrinks(drinks: movedDrinks)
        // 옮겨진 음료정보를 리턴한다
        return movedDrinksDetail
    }
    
    /// 유저가 음료 선택 시 진행 순서
    func buyDrink(orderDetail:OrderDetail) throws ->String {
        // 총 주문금액 변수계산. 잔액이 부족하면 에러
        let totalOrderPrice = try drinkInventory.calculatePrice(orderCount: orderDetail.drinkCount, balance: self.getMoney(), drinkType: orderDetail.drinkType)
        // 금액 사용
        try self.minusMoney(money: totalOrderPrice)
        
        // 인벤토리->주문내역 으로 음료 이동. 이동된 음료의 정보 저장
        let movedDrinksDetail = try orderedDrinks.addDrinks(drinks: drinkInventory.popDrinks(orderDetail: orderDetail))
        
        // 완료 메세지 리턴
        return "\(movedDrinksDetail.drinkName) \(movedDrinksDetail.drinkCount)개를 \(totalOrderPrice)원에 구입하였습니다."
    }
}

extension VendingMachine : VendingMachineAdminMenu {
    /// 음료 다수 제거 기능
    func removeDrinks(orderDetail:OrderDetail)throws->StoredDrinkDetail?{
        // 음료타입과 개수를 받아서 해당 음료를 리스트로 옮긴다
        let movedDrinks = try drinkInventory.popDrinks(orderDetail: orderDetail)
        
        // 리스트의 정보를 출력한다
        return movedDrinks.getDrinkDetail()
    }
    
    /// 관리자가 음료 제거 선택 시 진행 순서
    func reduceDrink(orderDetail:OrderDetail) throws ->String {
        // 음료 제거. 제거된 음료의 정보 저장
        guard let movedDrinkDetail = try removeDrinks(orderDetail: orderDetail) else {
            throw OutputView.errorMessage.notEnoughDrink
        }
        
        // 완료 메세지 리턴
        return "\(movedDrinkDetail.drinkName) \(movedDrinkDetail.drinkCount)개를 제거하였습니다."
    }
    
    /// 관리자가 음료 추가 선택시
    func duplicateDrink(orderDetail:OrderDetail) throws->String{
        // 음료 추가.
        let resultDetail = try drinkInventory.addDrinkSelfDuplicate(orderDetail: orderDetail)
        
        // 완료 메세지 리턴
        return "\(resultDetail.drinkName) \(resultDetail.drinkCount)개를 추가하였습니다."
    }
    
    /// 재고가 0이여도 가능한 음료추가함수
    func addBasicDrink(drinkType:DrinkType)throws{
        // 추가용 음료변수
        var basicDrink : Drink?
        // 음료타입에 따라서 음료 생성
        switch drinkType {
        case .chocoMilk : basicDrink = ChocoMilk(brand: "매일", size: 200, price: 800, name: "매일흰우유", manufacturingDateString: "20180919", lowFat: true, lowSugar: false)
        case .lowSugarChocoMilk : basicDrink = ChocoMilk(brand: "매일", size: 200, price: 1000, name: "매일초코초코", manufacturingDateString: "20180919", lowFat: true, lowSugar: true)
        case .coke : basicDrink =  Coke(brand: "코카콜라", size: 350, price: 1000, name: "코카콜라", manufacturingDateString: "20180919", usingPET: false, zeroCalorie: false)
        case .zeroCalorieCoke : basicDrink =  Coke(brand: "코카콜라", size: 350, price: 1200, name: "다이어트콜라", manufacturingDateString: "20180919", usingPET: false, zeroCalorie: true)
        case .hotTopCoffee : basicDrink = TopCoffee(brand: "매일", size: 200, price: 1500, name: "티오피 커피", manufacturingDateString: "20180919", hot: true, zeroSugar: true)
        case .energyDrink :  basicDrink = EnergyDrink(brand: "매일", size: 200, price: 20000, name: "핫식스", manufacturingDateString: "20180919", zeroCaffeine: true)
        case .none : throw OutputView.errorMessage.wrongDrink
        }
        // 생성한 음료 검사
        guard let newDrink = basicDrink else {
            throw OutputView.errorMessage.wrongDrink
        }
        // 음료 추가
        _ = try addDrink(drink: newDrink)
    }
    
    /// 자판기 생성용 기본 음료들 추가함수
    func addBasicDrinkSet()throws{
        try addBasicDrink(drinkType: DrinkType.chocoMilk)
        try addBasicDrink(drinkType: DrinkType.lowSugarChocoMilk)
        try addBasicDrink(drinkType: DrinkType.lowSugarChocoMilk)
        try addBasicDrink(drinkType: DrinkType.coke)
        try addBasicDrink(drinkType: DrinkType.coke)
        try addBasicDrink(drinkType: DrinkType.coke)
        try addBasicDrink(drinkType: DrinkType.zeroCalorieCoke)
        try addBasicDrink(drinkType: DrinkType.zeroCalorieCoke)
        try addBasicDrink(drinkType: DrinkType.zeroCalorieCoke)
        try addBasicDrink(drinkType: DrinkType.zeroCalorieCoke)
        try addBasicDrink(drinkType: DrinkType.hotTopCoffee)
        try addBasicDrink(drinkType: DrinkType.hotTopCoffee)
        try addBasicDrink(drinkType: DrinkType.hotTopCoffee)
        try addBasicDrink(drinkType: DrinkType.hotTopCoffee)
        try addBasicDrink(drinkType: DrinkType.hotTopCoffee)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
        try addBasicDrink(drinkType: DrinkType.energyDrink)
    }
}
