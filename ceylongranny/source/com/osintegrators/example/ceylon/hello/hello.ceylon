import ceylon.net.http.server { ...  }
import ceylon.io { ... }
import ceylon.io.charset { ... }
import ceylon.file { ... }
import ceylon.dbc { ... }
import ceylon.json { ... }
import ceylon.math.float { random }
import ceylon.math.integer { ... }
import javax.sql { ... }
import java.sql { DriverManager{ getConnection }, Connection{...}, ResultSet, Statement, PreparedStatement}
import java.lang { Class{ forName } }
import ceylon.collection { ... }
import ceylon.net.http { contentType }


void hello() {
	value server = createServer {
        //an endpoint, on the path /hello
        Endpoint {
            path =  startsWith("/index.html");
            //handle requests to this path
            service(Request request, Response response) =>
                    html("./index.html", request, response);
        	
    	},        
    	Endpoint {
            path =  startsWith("/main.css");
            //handle requests to this path
            service(Request request, Response response) =>
                    css("./main.css", request, response);
        	
    	},        
    	Endpoint {
            path =  startsWith("/scripts.js");
            //handle requests to this path
            service(Request request, Response response) =>
                    js("./scripts.js", request, response);
        	
    	},
    	Endpoint {
    		path =  startsWith("/contacts");
            //handle requests to this path
            service(Request request, Response response) =>
                    contacts(request, response);
        	
    	}
 
    };
    //start the server on port 8080
    server.start(8080);

	
}

void html(String filename, Request request, Response response) {
	value header = contentType("text/html", utf8); //if you don't include the charset you get a malformed header warning in the console
	response.addHeader(header);
	response.writeString(getFileContent(filename));
}

void css(String filename, Request request, Response response) {
	value header = contentType("text/css", utf8); 
	response.addHeader(header);
	response.writeString(getFileContent(filename));
}

void js(String filename, Request request, Response response) {
	value header = contentType("text/javascript", utf8);
	response.addHeader(header);
	response.writeString(getFileContent(filename));
}

void contacts(Request request, Response response) {
	if(request.method.equals("GET") && request.path.equals("/contacts")) {
		contactsGet(request, response);
	} else if (request.method.equals("GET") && request.path.startsWith("/contacts")){
		contactGet(request, response);
	} else if (request.method.equals("POST")) {
		contactsPost(request, response);
	} else if (request.method.equals("DELETE")) {
		contactDelete(request, response);
	} else if (request.method.equals("PUT")) {
		contactPut(request, response);		
	} else {
		print("different");
	}
}

void contactsPost(Request request, Response response) {
	print("contactsPost");
	value pathparsed = request.path.split("/", true, false);
	Integer id = parseInteger(pathparsed.last else "") else 0;
	String name = request.parameter("contact[name]") else "";
	
	String address = request.parameter("contact[address]") else "";
	String phone = request.parameter("contact[phone]") else "";
	String email = request.parameter("contact[email]") else ""; 
	print(name+","+address+","+phone+""+email);  
	
	Contact contact = Contact(id,name,address,phone,email);
	insertContact(contact);
}

void contactPut(Request request, Response response) {
	print("contactPut");
	value pathparsed = request.path.split("/", true, false);
	Integer id = parseInteger(pathparsed.last else "") else 0;
	String name = request.parameter("contact[name]") else "";
	
	String address = request.parameter("contact[address]") else "";
	String phone = request.parameter("contact[phone]") else "";
	String email = request.parameter("contact[email]") else ""; 
	print(name+","+address+","+phone+""+email);  
	
	Contact contact = Contact(id,name,address,phone,email);
	updateContact(contact);
}

void contactGet(Request request, Response response) {
	print("contactGet");
	value pathparsed = (
	                        request.path.span(
	                                            (request.path.firstOccurrence("/contacts/") else 0)+"/contacts/".size,
	                                            (request.path.firstOccurrence(".json") else 0) - 1
	                                         ) 
	                   );
	Integer id = parseInteger(pathparsed.string) else 0;
	value header = contentType("application/json", utf8);
	
	response.addHeader(header);
	Contact? contact = getContact(id);
	Object json = contactToJson(contact);
	print(json.string);
	response.writeString(json.string);	
}


void contactDelete(Request request, Response response) {
	print("contactDelete");
		value pathparsed = (
	                        request.path.span(
	                                            (request.path.firstOccurrence("/contacts/") else 0)+"/contacts/".size,
	                                            request.path.size -1
	                                         ) 
	                   );
	Integer id = parseInteger(pathparsed.string) else 0;
	//Integer ret = 
	deleteContact(id);
	//value header = contentType("application/json", utf8);
	
	//response.addHeader(header);
	//	response.writeString(Object {
	//	"id" -> id,
	//	"return" -> ret 
	//}.string);
}


void contactsGet(Request request, Response response) {
	print("contactsGet");
	value header = contentType("application/json", utf8);
	response.addHeader(header);
	LinkedList<Contact> list = getContactList();
	Array json = contactListToJson(list);
	print(json.string);
	response.writeString(json.string);	
}


String getFileContent(String filename) {
	value filePath = parsePath(filename);
	variable String retval = "";
	if (is File file = filePath.resource) {
	    value reader = file.reader();
	    try {
	        //variable String? line = "";
	        while (exists line = reader.readLine()) { //there is no dowhile and you can't really check for nulls but readline may return one...
	            retval += line + "\n" ;
	        } 
	    }
	    finally {
	        reader.destroy();
	    }
	}
	else {
	    print("file does not exist");
	}
	return retval;
}


Connection getDbConnection() {
	String userName = "granny";
    String password = "granny";
    String url = "jdbc:postgresql://localhost/grannydb";
    forName("org.postgresql.Driver");
    return getConnection (url, userName, password);
}

LinkedList<Contact> getContactList() {
	// there doesn't appear to be a way to both return a list and use an array list...you have to care.
	LinkedList<Contact> result = LinkedList<Contact>();
	String query = "select * from address";
	Connection conn = getDbConnection();
	Statement stmt = conn.createStatement();
	ResultSet rs = stmt.executeQuery(query);
	while (rs.next()) {
		Contact contact = Contact(rs.getInt("id"), rs.getString("name"), rs.getString("address"), rs.getString("phone"), rs.getString("email"));
		result.add(contact); 
	}
	rs.close();
	stmt.close();
	conn.close();
	return result;
}

Integer deleteContact(Integer id) {
	print(id);
	// there doesn't appear to be a way to both return a list and use an array list...you have to care.
	String query = "delete from address where id = ?";
	Connection conn = getDbConnection();
	PreparedStatement stmt = conn.prepareStatement(query);
	stmt.setInt(1, id);
	Integer retval = stmt.executeUpdate();
	stmt.close();
	conn.close();
	return retval;
}

Contact? getContact(Integer id) {
	print(id);
	// there doesn't appear to be a way to both return a list and use an array list...you have to care.
	String query = "select * from address where id = ?";
	Connection conn = getDbConnection();
	PreparedStatement stmt = conn.prepareStatement(query);
	stmt.setInt(1, id);
	ResultSet rs = stmt.executeQuery();
	if (rs.next()) {
		Contact contact = Contact(rs.getInt("id"), rs.getString("name"), rs.getString("address"), rs.getString("phone"), rs.getString("email"));
		rs.close();
		stmt.close();
		conn.close();
		return contact;
	}
	rs.close();
	stmt.close();
	conn.close();
	return null;
}

Integer updateContact(Contact contact) {
	Connection conn = getDbConnection();
	PreparedStatement stmt = conn.prepareStatement("update address set name = ?, address = ?, phone = ?, email = ? where id = ?");
	stmt.setString(1, contact.name);
	stmt.setString(2, contact.address);
	stmt.setString(3, contact.phone);
	stmt.setString(4, contact.email);
	stmt.setInt(5, contact.id);
	Integer retval = stmt.executeUpdate();
	stmt.close();
	conn.close();
	return retval; 
}

Integer insertContact(Contact contact) { 
	Integer rnd = (random() * ((0 - (2^31)) + 1)).integer;
	Connection conn = getDbConnection();
	PreparedStatement stmt = conn.prepareStatement("insert into address (\"id\", \"name\", \"address\", \"phone\",\"email\") values (?,?,?,?,?)");
	stmt.setInt(1, rnd);
	stmt.setString(2, contact.name);
	stmt.setString(3, contact.address);
	stmt.setString(4, contact.phone);
	stmt.setString(5, contact.email);
	Integer retval = stmt.executeUpdate();
	stmt.close();
	conn.close();
	return retval; 
} 

Array contactListToJson(LinkedList<Contact> contacts) {
	value json = Array();
	for (contact in contacts) {
		json.add(contactToJson(contact));
	}
	return json;
}

Object contactToJson(Contact? contact) {
	if (exists contact) {
	return Object {
		"id" -> contact.id,
		"name" -> contact.name,
		"address" -> contact.address,
		"phone" -> contact.phone,
		"email" -> contact.email
	};
	} else {
		return Object();
	}

}
