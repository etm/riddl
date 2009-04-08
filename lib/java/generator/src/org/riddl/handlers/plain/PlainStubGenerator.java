package org.riddl.handlers.plain;

import org.riddl.generator.MessagePartContentStubGenerator;
import org.riddl.generator.RiddlDescriptionGenerator;

import com.sun.codemodel.JType;

public class PlainStubGenerator extends MessagePartContentStubGenerator {

	@Override
	public JType generate() 
	{
		String type = getPartContent().get(0).getAttribute("type");
		JType jType;
		try 
		{
			jType = RiddlDescriptionGenerator.getOrCreateType(type, getCodeModel());
		} 
		catch (ClassNotFoundException e) 
		{
			throw new RuntimeException(e);
		}
		return jType;
	}

	@Override
	public String getURI() 
	{
		return "http://riddl.org/ns/part-plugins/plain";
	}

}
