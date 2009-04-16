package org.riddl.generator;

import java.io.InputStream;

import com.sun.codemodel.JType;

public class DefaultMessagePartContentStubGenerator extends
		MessagePartContentStubGenerator {

	@Override
	public JType generate() 
	{
		return this.getCodeModel()._ref(InputStream.class);
	}

	@Override
	public String getURI() {
		return null;
	}

}
