package org.riddl.generator;

import java.util.HashMap;
import java.util.Map;

public class MessagePartContentStubGeneratorFactory 
{
	
	private static MessagePartContentStubGeneratorFactory instance;
	
	private Map<String, MessagePartContentStubGenerator> handlers = new HashMap<String, MessagePartContentStubGenerator>();
	
	private Map<String, MessagePartContentStubGenerator> defaultMimeTypehandlers = new HashMap<String, MessagePartContentStubGenerator>();
	
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
		MessagePartContentStubGenerator result = handlers.get(handlerURI);
		if(result == null)
		{
			throw new HandlerNotFoundException(handlerURI);
		}
		return result;
	}

	public MessagePartContentStubGenerator getDefaultHandlerForMimeType(String mimeType)
	{
		MessagePartContentStubGenerator result = defaultMimeTypehandlers.get(mimeType);
		if(result == null)
		{
			throw new HandlerNotFoundException(mimeType);
		}
		return result;
	}


}
