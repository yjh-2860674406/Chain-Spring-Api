package cn.org.gry.chainmaker.contract;

import cn.org.gry.chainmaker.base.BaseContractEvm;
import org.springframework.stereotype.Component;

/**
 * @author yejinhua  Email:yejinhua@gzis.ac.cn
 * @version 1.0
 * @description 生产批次合约
 * @since 2023/12/18 9:36
 * Copyright (C) 2022-2023 CASEEDER, All Rights Reserved.
 * 注意：本内容仅限于内部传阅，禁止外泄以及用于其他的商业目的
 */
@Component
public class ContractProductLotEvm extends BaseContractEvm {
    ContractProductLotEvm() {
        this.contractName = "ProductLot" + super.version;
        this.EVM_CONTRACT_FILE_PATH = "src/main/resources/contract/ProductLot.bin";
    }
}
