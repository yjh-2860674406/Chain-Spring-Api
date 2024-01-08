package cn.org.gry.chainmaker.aop;

/**
 * @author yejinhua  Email:yejinhua@gzis.ac.cn
 * @version 1.0
 * @description
 * @since 2024/1/8 14:54
 * Copyright (C) 2022-2023 CASEEDER, All Rights Reserved.
 * 注意：本内容仅限于内部传阅，禁止外泄以及用于其他的商业目的
 */
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

import java.util.Arrays;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class LoggableAspect {
    @Before("execution(* cn.org.gry.chainmaker.controller.*.*(..))")
    public void logBefore(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        Object[] args = joinPoint.getArgs();

        System.out.println("LoggableAspect: Before " + className + "." + methodName + " execution. Arguments: " + arrayToString(args));
    }

    @AfterReturning(pointcut = "execution(* cn.org.gry.chainmaker.controller.*.*(..))", returning = "result")
    public void logAfterReturning(JoinPoint joinPoint, Object result) {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();

        System.out.println("LoggableAspect: After " + className + "." + methodName + " execution. Result: " + result);
    }

    @AfterThrowing(pointcut = "execution(* cn.org.gry.chainmaker.controller.*.*(..))", throwing = "exception")
    public void logAfterThrowing(JoinPoint joinPoint, Throwable exception) {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        Object[] args = joinPoint.getArgs();

        System.out.println("LoggableAspect: After " + className + "." + methodName + " threw an exception. Arguments: " + arrayToString(args) + ", Exception: " + exception.getMessage());
    }

    private String arrayToString(Object[] array) {
        if (array == null) {
            return "null";
        }

        StringBuilder result = new StringBuilder("[");
        for (Object obj : array) {
            result.append(obj).append(", ");
        }

        if (result.length() > 1) {
            result.setLength(result.length() - 2);
        }

        result.append("]");
        return result.toString();
    }
}
