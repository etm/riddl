package org.riddl.generator;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import javax.lang.model.element.Modifier;

public class Field 
{
	private List<Modifier> modifiers = new ArrayList<Modifier>();
	private String type = "String";
	private String name = null;
	private int indentation = 1;
	private String initializationValue = null;
	private boolean quoteInitializationValue = false;
	
	private static boolean hasMoreThanOneProtectionModifier(
			Collection<Modifier> modifiers) 
	{
		//Modifier.
		ArrayList<Modifier> modifiersCopy = new ArrayList<Modifier>(modifiers);
		//modifiersCopy.retainAll(PROTECTION_MODIFIERS);
		return modifiersCopy.size() > 1;
	}
	
	public boolean isQuoteInitializationValue() {
		return quoteInitializationValue;
	}
	public void setQuoteInitializationValue(boolean quoteInitializationValue) {
		this.quoteInitializationValue = quoteInitializationValue;
	}
	public Collection<Modifier> getModifiers() {
		return modifiers;
	}
	public void setModifiers(Modifier... prefixes) {
		this.modifiers = new ArrayList<Modifier>(Arrays.asList(prefixes));
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
		
		for(Modifier modifier : modifiers)
		{
			declarationBuilder.append(modifier + " ");
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
	
	private boolean isModifierListValid(Collection<Modifier> modifiers)
	{
		if(hasMoreThanOneProtectionModifier(modifiers))
		{
			return false;
		}
		
		
		return true;
	}


}
