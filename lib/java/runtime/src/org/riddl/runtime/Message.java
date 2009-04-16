package org.riddl.runtime;

public abstract class Message
{
	private String name;
	protected Part[] parts;
	protected Parameter[] parameters;
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public Part[] getParts() {
		return parts;
	}
	public Parameter[] getParameters() {
		return parameters;
	}
	public int getPartCount() {
		// TODO Paramters that come as parts?
		return parts.length;
	}
	
	

}
