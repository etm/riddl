package org.riddl.runtime;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import sun.reflect.generics.reflectiveObjects.NotImplementedException;

import com.sun.jersey.api.NotFoundException;
import com.sun.jersey.multipart.BodyPart;
import com.sun.jersey.multipart.MultiPart;

public abstract class Resource 
{
	
	
	@GET
	public Response get(MultiPart request)
	{
		return renderMessageToResponse(get(createMessageFromMultipartRequest(request,getGetInputMessages())));
	}
	protected Message get(Message message)
	{
		throw new NotFoundException();
	}

	@POST
	public Response post(MultiPart request)
	{
		return renderMessageToResponse(post(createMessageFromMultipartRequest(request,getPostInputMessages())));
	}
	protected Message post(Message message)
	{
		throw new NotFoundException();
	}
	
	@PUT
	public Response put(MultiPart request)
	{
		return renderMessageToResponse(put(createMessageFromMultipartRequest(request,getPutInputMessages())));
	}
	protected Message put(Message message)
	{
		throw new NotFoundException();
	}
	
	@DELETE
	public Response delete(MultiPart request)
	{
		return renderMessageToResponse(delete(createMessageFromMultipartRequest(request,getDeleteInputMessages())));
	}
	protected Message delete(Message message)
	{
		throw new NotFoundException();
	}

	@SuppressWarnings("unchecked")
	protected Class<? extends Message>[] getGetInputMessages(){return new Class[0];}
	@SuppressWarnings("unchecked")
	protected Class<? extends Message>[] getPutInputMessages(){return new Class[0];}
	@SuppressWarnings("unchecked")
	protected Class<? extends Message>[] getPostInputMessages(){return new Class[0];}
	@SuppressWarnings("unchecked")
	protected Class<? extends Message>[] getDeleteInputMessages(){return new Class[0];}
	
	
	private Response renderMessageToResponse(Message message)
	{
		throw new NotImplementedException();
	}
	
	private Message createMessageFromMultipartRequest(MultiPart request, Class<? extends Message>[] classes)
	{
		Message result = null;
		
		List<Message> messageList = new ArrayList<Message>(classes.length);
		for(Class<? extends Message> messageClass : classes)
		{
			try {
				messageList.add(messageClass.newInstance());
			} catch (InstantiationException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		List<BodyPart> bodyParts = request.getBodyParts();
		for(Iterator<Message> i = messageList.iterator();i.hasNext();)
		{
			Message message = i.next();
			if(message.getPartCount() != bodyParts.size())
			{
				i.remove();
			}
		}
		
		for(Iterator<Message> i = messageList.iterator();i.hasNext();)
		{
			Message message = i.next();
			Part[] parts = message.getParts();
			for(int j = 0; j<parts.length; j++)
			{
				BodyPart bodyPart = bodyParts.get(j);
				if(!MediaType.valueOf(parts[j].getType()).isCompatible(bodyPart.getMediaType()))
				{
					i.remove();
					break;
				}
				try {
					if(parts[j].getName().equals(bodyPart.getParameterizedHeaders().getFirst("content-disposition").getParameters().get("name")))
					{
						i.remove();
						break;
					}
				} catch (ParseException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
		
		if(messageList.size() > 0)
		{
			result = messageList.get(0); // If there are more messages that match the request, we just take the first ...
			Part[] parts = result.getParts();
			for(int i = 0; i<parts.length; i++)
			{
				result.parts[i].setValue(MessagePartHandlerFactory.getInstance().getHandlerByURIString(parts[i].getHandler()).createMessageFromBodyPart(bodyParts.get(i)));
			}
		}
		
		
		
		
		
		return result;
	}

}
