package org.riddl.generator;

import java.io.File;
import java.util.List;

import org.w3c.dom.Element;


public abstract class MessagePartContentStubGenerator 
{
	private String messagesPackage;
	private File messageOutputDirectory;
	private List<Element> partContent;
	
	
	
	
	public List<Element> getPartContent() {
		return partContent;
	}
	public void setPartContent(List<Element> partContent) {
		this.partContent = partContent;
	}
	public String getMessagesPackage() {
		return messagesPackage;
	}
	public void setMessagesPackage(String messagesPackage) {
		this.messagesPackage = messagesPackage;
	}
	public File getMessageOutputDirectory() {
		return messageOutputDirectory;
	}
	public void setMessageOutputDirectory(File messageOutputDirectory) {
		this.messageOutputDirectory = messageOutputDirectory;
	}
	public abstract String getURI();
	public abstract String generate();
	
	

}
