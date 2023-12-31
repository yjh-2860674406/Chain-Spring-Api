package cn.org.gry.chainmaker.domain.service;

import cn.org.gry.chainmaker.base.BaseContractEvm;
import cn.org.gry.chainmaker.base.erc721.ERC721;
import cn.org.gry.chainmaker.contract.ContractRawMaterialsEvm;
import cn.org.gry.chainmaker.utils.ChainMakerUtils;
import cn.org.gry.chainmaker.utils.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Utf8String;
import org.web3j.abi.datatypes.generated.Uint128;
import org.web3j.abi.datatypes.generated.Uint256;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.Collections;

/**
 * @author yejinhua  Email:yejinhua@gzis.ac.cn
 * @version 1.0
 * @description
 * @since 2023/12/18 17:12
 * Copyright (C) 2022-2023 CASEEDER, All Rights Reserved.
 * 注意：本内容仅限于内部传阅，禁止外泄以及用于其他的商业目的
 */
@Component
public class RM extends ERC721 {
    private final ContractRawMaterialsEvm contractRawMaterialsEvm;

    @Autowired
    private UserInfoService userInfoService;

    @Autowired
    public RM(ContractRawMaterialsEvm contractRawMaterialsEvm) {
        this.contractRawMaterialsEvm = contractRawMaterialsEvm;
        setBaseContractEvm(contractRawMaterialsEvm);
    }

    public Result mint(String tokenURI, String initSum, String name) {
        return contractRawMaterialsEvm.invokeContract(
                "mint",
                Arrays.asList(
                        new Utf8String(tokenURI),
                        new Uint128(ChainMakerUtils.doubleString2BigInteger(initSum)),
                        new Utf8String(name)),
                Collections.singletonList(TypeReference.create(Uint256.class)),
                Collections.singletonList("token"));
    }

    public Result transferFrom(Long from, Long to, BigInteger tokenId) {
        return contractRawMaterialsEvm.invokeContract(
                "transferFrom",
                Arrays.asList(new Address(userInfoService.getAddressByUid(from)), new Address(userInfoService.getAddressByUid(to)), new Uint256(tokenId)),
                Collections.emptyList(),
                Collections.emptyList());
    }

    public Result transfer(Long to, BigInteger tokenId) {
        return contractRawMaterialsEvm.invokeContract(
                "transfer",
                Arrays.asList(new Address(userInfoService.getAddressByUid(to)), new Uint256(tokenId)),
                Collections.emptyList(),
                Collections.emptyList());
    }

    @Override
    public void setBaseContractEvm(BaseContractEvm baseContractEvm) {
        super.baseContractEvm = baseContractEvm;
    }
}
