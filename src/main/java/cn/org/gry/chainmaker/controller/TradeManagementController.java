package cn.org.gry.chainmaker.controller;

import cn.org.gry.chainmaker.domain.entity.PP;
import cn.org.gry.chainmaker.domain.entity.TradeManagement;
import cn.org.gry.chainmaker.utils.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigInteger;

/**
 * @author yejinhua  Email:yejinhua@gzis.ac.cn
 * @version 1.0
 * @description
 * @since 2023/12/20 11:09
 * Copyright (C) 2022-2023 CASEEDER, All Rights Reserved.
 * 注意：本内容仅限于内部传阅，禁止外泄以及用于其他的商业目的
 */
@RestController
@RequestMapping("/contract/trademanagement.do")
public class TradeManagementController {
    @Autowired
    private TradeManagement tradeManagement;

    @RequestMapping(params = "action=setLotContract")
    public void setLotContract (@RequestParam("lotAddress") String lotAddress) {
        tradeManagement.setLotContract(lotAddress);
    }

    @RequestMapping(params = "action=setRawMaterialsContract")
    public void setRawMaterialsContract (@RequestParam("rawMaterialsAddress") String rawMaterialsAddress) {
        tradeManagement.setRawMaterialsContract(rawMaterialsAddress);
    }

    @RequestMapping(params = "action=setPackagedProductsContract")
    public void setPackagedProductsContract (@RequestParam("packagedProductsAddress") String packagedProductsAddress) {
        tradeManagement.setPackagedProductsContract(packagedProductsAddress);
    }

    @RequestMapping(params = "action=RegisterSupplier")
    public void RegisterSupplier (@RequestParam("supplierAddress") String supplierAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterSupplier(supplierAddress, name);
    }

    @RequestMapping(params = "action=RegisterProducer")
    public void RegisterProducer (@RequestParam("producerAddress") String producerAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterProducer(producerAddress, name);
    }

    @RequestMapping(params = "action=RegisterDealer")
    public void RegisterDealer (@RequestParam("dealerAddress") String dealerAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterDealer(dealerAddress, name);
    }

    @RequestMapping(params = "action=RegisterWholesaler")
    public void RegisterWholesaler (@RequestParam("wholesalerAddress") String wholesalerAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterWholesaler(wholesalerAddress, name);
    }

    @RequestMapping(params = "action=RegisterRetailer")
    public void RegisterRetailer (@RequestParam("retailerAddress") String retailerAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterRetailer(retailerAddress, name);
    }

    @RequestMapping(params = "action=RegisterCustomer")
    public void RegisterConsumer (@RequestParam("customerAddress") String customerAddress, @RequestParam("name") String name) {
        tradeManagement.RegisterCustomer(customerAddress, name);
    }

    @RequestMapping(params = "action=getRawMaterialsNFT")
    public Result getRawMaterialsNFT (@RequestParam("rawMaterialsId") BigInteger rawMaterialsId) {
        return tradeManagement.getRawMaterialsNFT(rawMaterialsId);
    }

    @RequestMapping(params = "action=getPackagedProductsNFT")
    public Result getPackagedProductsNFT (@RequestParam("packagedProductsId") BigInteger packagedProductsId) {
        return tradeManagement.getPackagedProductsNFT(packagedProductsId);
    }

    @RequestMapping(params = "action=getProductsFromPackage")
    public Result getProductsFromPackage (
            @RequestParam("tokenId") BigInteger tokenId
    )
    {
        return tradeManagement.getProductsFromPackage(tokenId);
    }

    @RequestMapping(params = "action=listProducts")
    public Result listProducts (
            @RequestParam("owner") String owner,
            @RequestParam("tokenID") BigInteger tokenID
    )
    {
        return tradeManagement.listProducts(owner, tokenID);
    }

    @RequestMapping(params = "action=getStatist")
    public Result getStatist ()
    {
        return tradeManagement.getStatist();
    }

    @RequestMapping(params = "action=listRawMaterials")
    public Result listRawMaterials (
            @RequestParam("owner") String owner,
            @RequestParam("tokenID") BigInteger tokenID
    )
    {
        return tradeManagement.listRawMaterials(owner, tokenID);
    }
}