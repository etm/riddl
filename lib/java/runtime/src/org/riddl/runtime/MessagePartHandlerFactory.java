package org.riddl.runtime;

public class MessagePartHandlerFactory {

	private static MessagePartHandlerFactory instance = new MessagePartHandlerFactory();
	
	public static MessagePartHandlerFactory getInstance() 
	{
		return instance;
	}
	
	public MessagePartHandler getHandlerByURIString(String handler) 
	{
		return null;
		
	}

}
