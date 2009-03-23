package org.riddl.generator;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Field 
{
	private List<String> prefixes = new ArrayList<String>();
	private String type = "String";
	private String name = "string";
	private int indentation = 1;
	private String initializationValue = null;
	private boolean quoteInitializationValue = false;
	
	
	
	public boolean isQuoteInitializationValue() {
		return quoteInitializationValue;
	}
	public void setQuoteInitializationValue(boolean quoteInitializationValue) {
		this.quoteInitializationValue = quoteInitializationValue;
	}
	public List<String> getPrefixes() {
		return prefixes;
	}
	public void setPrefixes(String... prefixes) {
		this.prefixes = new ArrayList<String>(Arrays.asList(prefixes));
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getIndentation() {
		return indentation;
	}
	public void setIndentation(int indentation) {
		this.indentation = indentation;
	}
	public String getInitializationValue() {
		return initializationValue;
	}
	public void setInitializationValue(String initializationValue) {
		this.initializationValue = initializationValue;
	}
	
	public String createJavaString()
	{
		StringBuilder declarationBuilder = new StringBuilder();
		for(int i = 0; i<indentation; i++)
		{
			declarationBuilder.append("\t");
		}
		
		for(String prefix : prefixes)
		{
			declarationBuilder.append(prefix + " ");
		}
		
		declarationBuilder.append(type + " ");
		declarationBuilder.append(name + " ");
		
		if(initializationValue != null)
		{
			declarationBuilder.append("= ");
			if(quoteInitializationValue)
			{
				declarationBuilder.append("\"" + initializationValue + "\"");
			}
			else
			{
				declarationBuilder.append("\"" + initializationValue + "\"");
			}
		}
		declarationBuilder.append(";\n");
		
		return declarationBuilder.toString();
	}

}
