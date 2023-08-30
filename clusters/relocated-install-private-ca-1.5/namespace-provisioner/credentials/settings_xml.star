def settings_xml(url, password, username): 
    returnVal = """<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
        <mirrors>
            <mirror>
                <id>internal</id>
                <name>Internal Repo</name>
                <url>{}</url>
                <mirrorOf>*</mirrorOf>
            </mirror>
        </mirrors>""".format(url)
    if ((username and "" != username) or (password and "" != password)): 
        returnVal += """
        <servers>
             <server>
                <id>internal</id>
                <username>{}</username>
                <password>{}</password>
             </server>
        </servers>""".format(username, password)
    end
    returnVal += """
    </settings>"""
    return returnVal
end