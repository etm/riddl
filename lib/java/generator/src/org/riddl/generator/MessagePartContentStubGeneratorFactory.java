package org.riddl.generator;

import java.util.HashMap;
import java.util.Map;

public class MessagePartContentStubGeneratorFactory 
{
	
	private static MessagePartContentStubGeneratorFactory instance;
	
	private Map<String, MessagePartContentStubGenerator> stubGenerators = new HashMap<String, MessagePartContentStubGenerator>();
	
	private Map<String, MessagePartContentStubGenerator> defaultMimeTypeStubGenerators = new HashMap<String, MessagePartContentStubGenerator>();
	
	private MessagePartContentStubGeneratorFactory()
	{}
	
	public static MessagePartContentStubGeneratorFactory getInstance()
	{
		if(instance == null)
		{
			instance = new MessagePartContentStubGeneratorFactory();
		}
		return instance;
	}
	
	public MessagePartContentStubGenerator getHandlerByURIString(String handlerURI)
	{
		MessagePartContentStubGenerator result = stubGenerators.get(handlerURI);
		if(result == null)
		{
			throw new HandlerNotFoundException(handlerURI);
		}
		return result;
	}

	public MessagePartContentStubGenerator getDefaultHandlerForMimeType(String mimeType)
	{
		MessagePartContentStubGenerator result = defaultMimeTypeStubGenerators.get(mimeType);
		if(result == null)
		{
			throw new HandlerNotFoundException(mimeType);
		}
		return result;
	}
	
	public void registerStubGeneratorForURI(String handlerURI, MessagePartContentStubGenerator stubGenerator)
	{
		this.stubGenerators.put(handlerURI, stubGenerator);
	}


}
