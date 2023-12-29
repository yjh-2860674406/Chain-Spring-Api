package cn.org.gry.chainmaker.config;

/**
 * @author yejinhua  Email:yejinhua@gzis.ac.cn
 * @version 1.0
 * @description
 * @since 2023/12/20 10:22
 * Copyright (C) 2022-2023 CASEEDER, All Rights Reserved.
 * 注意：本内容仅限于内部传阅，禁止外泄以及用于其他的商业目的
 */

import org.chainmaker.sdk.config.NodeConfig;
import org.chainmaker.sdk.config.SdkConfig;
import org.chainmaker.sdk.utils.FileUtils;
import org.chainmaker.sdk.utils.UtilsException;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Semaphore;

public class SdkConfigPool {
    private final BlockingQueue<SdkConfig> objectPool;
    private final Semaphore semaphore;
    private static final String SDK_CONFIG = "sdk_config.yml";

    public SdkConfigPool(int poolSize) throws UtilsException, IOException {
        objectPool = new ArrayBlockingQueue<>(poolSize);
        semaphore = new Semaphore(poolSize, true);

        // 初始化对象池
        for (int i = 0; i < poolSize; i++) {
            objectPool.offer(createSDKConfig());
        }
    }

    public SdkConfig acquire() throws InterruptedException {
        // 从池中获取对象
        semaphore.acquire();
        return objectPool.poll();
    }

    public void release(SdkConfig sdkConfig) {
        // 将对象放回池中
        objectPool.offer(sdkConfig);
        semaphore.release();
    }

    private SdkConfig createSDKConfig() throws IOException, UtilsException {
        // 加载配置文件成Yaml对象
        Yaml yaml = new Yaml();
        InputStream in = SdkConfigPool.class.getClassLoader().getResourceAsStream(SDK_CONFIG);

        // 将Yaml对象转换为SDKConfig
        SdkConfig sdkConfig;
        sdkConfig = yaml.loadAs(in, SdkConfig.class);
        assert in != null;
        in.close();

        // 从SDKConfig中获取节点配置信息
        for (NodeConfig nodeConfig : sdkConfig.getChainClient().getNodes()) {
            List<byte[]> tlsCaCertList = new ArrayList<>();
            if (nodeConfig.getTrustRootPaths() != null) {
                for (String rootPath : nodeConfig.getTrustRootPaths()) {
                    List<String> filePathList = FileUtils.getFilesByPath(rootPath);
                    for (String filePath : filePathList) {
                        tlsCaCertList.add(FileUtils.getFileBytes(filePath));
                    }
                }
            }
            byte[][] tlsCaCerts = new byte[tlsCaCertList.size()][];
            tlsCaCertList.toArray(tlsCaCerts);
            nodeConfig.setTrustRootBytes(tlsCaCerts);
        }
        return sdkConfig;
    }
}
