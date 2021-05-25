package com.marianhello.bgloc;

import com.marianhello.bgloc.test.TestConstants;

public class TestResourceResolver extends ResourceResolver {

    public TestResourceResolver() {

    }

    public String getAuthority() {
        return TestConstants.Authority;
    }
}
