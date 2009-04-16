package org.riddl.runtime;

public class Part
{
	private String name;
	private String type;
	private String handler;
	private Object value;
	
	public Part(String name, String type, String handler, Object value) {
		super();
		this.name = name;
		this.type = type;
		this.handler = handler;
		this.value = value;
	}
	
	public String getHandler() {
		return handler;
	}
	public void setHandler(String handler) {
		this.handler = handler;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public Object getValue() {
		return value;
	}
	public void setValue(Object value) {
		this.value = value;
	}
	
	
}
