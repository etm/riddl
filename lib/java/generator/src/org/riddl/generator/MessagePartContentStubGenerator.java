package org.riddl.generator;

import java.io.File;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.w3c.dom.Element;

import com.sun.codemodel.JClass;
import com.sun.codemodel.JCodeModel;
import com.sun.codemodel.JPackage;
import com.sun.codemodel.JType;


public abstract class MessagePartContentStubGenerator 
{
	private JPackage partPackage;
	private List<Element> partContent;
	private JCodeModel codeModel;
	private File baseDirectory;
	private Map<JClass,Element> messageParts;
	
	
	public File getBaseDirectory() {
		return baseDirectory;
	}
	public void setBaseDirectory(File baseDirectory) {
		this.baseDirectory = baseDirectory;
	}
	public JPackage getPartPackage() {
		return partPackage;
	}
	public void setPartPackage(JPackage partPackage) {
		this.partPackage = partPackage;
	}
	public JCodeModel getCodeModel() {
		return codeModel;
	}
	public void setCodeModel(JCodeModel codeModel) {
		this.codeModel = codeModel;
	}
	public List<Element> getPartContent() {
		return partContent;
	}
	public void setPartContent(List<Element> partContent) {
		this.partContent = partContent;
	}
	public abstract String getURI();
	public abstract JType generate();
	
	

}
