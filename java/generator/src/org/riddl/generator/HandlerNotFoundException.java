package org.riddl.generator;

public class HandlerNotFoundException extends RuntimeException 
{
	public HandlerNotFoundException(String identifier) 
	{
		super(identifier);
	}
}
