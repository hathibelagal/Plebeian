// Copyright 2017 Hathibelagal
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(new Plebeian());
}

class Plebeian extends StatefulWidget {
    _Plebeian createState() => new _Plebeian();
}

class _Plebeian extends State<Plebeian> {

    String appName = "Plebeian";
    String appVersion = "0.1";
    var http = createHttpClient();
    String BASE_URL = "https://www.reddit.com";
    String COMMENTS_BASE_URL = "https://www.reddit.com/comments/";

    String currentSubreddit = "/r/AskReddit";
    List<Post> posts = [];
    bool loading = true;

    String currentPostId = "";
    List<Comment> comments = [];

    List<String> subreddits = [
        '/r/AskReddit',
        '/r/Science',
        '/r/Android',
        '/r/Technology',
        '/r/WorldNews',
        '/r/Programming',
        '/r/DartLang',
        '/r/India',
        '/r/Europe',
        '/r/News',
        '/r/Futurology',
        '/r/IAmA',
        '/r/TodayILearned',
        '/r/Politics',
        '/r/Gaming',
        '/r/ShowerThoughts',
        '/r/Movies',
    ];

    @override
    void initState() {
        super.initState();
        loadPosts();
    }

    void loadPosts() async {
        List<Post> currentPosts = [];

        Map<String, String> headers = new Map<String, String>();
        headers["User-Agent"] = "$appName $appVersion";

        var response = await http.read("${BASE_URL}${currentSubreddit}/.json", headers: headers);
        
        var jsonData = JSON.decode(response)["data"]["children"];

        for(int i=0;i<jsonData.length;i++) {
            Post post = new Post();
            post.title = jsonData[i]["data"]["title"];
            post.author = jsonData[i]["data"]["author"];
            post.url = jsonData[i]["data"]["url"];
            post.permalink = jsonData[i]["data"]["permalink"];
            post.points = jsonData[i]["data"]["score"];
            post.comments = jsonData[i]["data"]["num_comments"];
            post.id = jsonData[i]["data"]["id"];
            post.self = jsonData[i]["data"]["is_self"];
            currentPosts.add(post);        
        }

        setState(() {
            loading = false;
            posts = currentPosts;
        });
    }

    void addToComments(List<Comment> currentComments, var jsonData) {
        try {
            for(int i=0;i<jsonData.length;i++) {
                if(jsonData[i]["kind"] != "t1")
                    continue;

                Comment comment = new Comment();
                comment.text = jsonData[i]["data"]["body"];
                comment.author = jsonData[i]["data"]["author"];
                comment.points = jsonData[i]["data"]["score"];
                comment.depth = jsonData[i]["data"]["depth"];
                currentComments.add(comment);

                if(jsonData[i]["data"].containsKey("replies") && jsonData[i]["data"]["replies"] != "") {            
                    var replies = jsonData[i]["data"]["replies"]["data"]["children"];
                    addToComments(currentComments, replies);
                }
            }
        } catch(e) {
            print("ERROR: " + jsonData);
        }
    }

    void loadComments() async {
        List<Comment> currentComments = [];

        Map<String, String> headers = new Map<String, String>();
        headers["User-Agent"] = "$appName $appVersion";

        var response = await http.read("${COMMENTS_BASE_URL}${currentPostId}/.json", headers: headers);

        var jsonData = JSON.decode(response)[1]["data"]["children"];

        addToComments(currentComments, jsonData);

        print("Rendering ${currentComments.length} items");

        setState(() {
            loading = false;
            comments = currentComments;
        });
    }

    @override
    Widget build(BuildContext context) {
        return new MaterialApp(
          title: appName,
          theme: new ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: new Scaffold(
                appBar: new AppBar(
                    title: new Text(appName)
                ),
                drawer: new Drawer(
                    child: new ListView.builder(
                            padding: new EdgeInsets.all(16.0),
                            itemCount: subreddits.length,
                            itemExtent: 50.0,
                            itemBuilder: (BuildContext context, int i) {
                                return new ListTile(
                                    leading: const Icon(Icons.arrow_right),
                                    title: new Text(subreddits[i], 
                                        textScaleFactor: 1.0,
                                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5)
                                    ),
                                    onTap: () {
                                        currentSubreddit = subreddits[i];
                                        reloadMainScreen(context);
                                    }
                                );
                            }
                        )
                ),
                body: getPage()
            ),
        );
    }

    Widget getPage() {
        if(!loading) {
            return new ListView.builder(
                itemCount: posts.length,
                itemBuilder: (BuildContext context, int i) {
                    return new Container(
                        child: new Card(
                                child: new Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                        new Padding(
                                            child: new Text("\u{1F44D} ${posts[i].points}    \u{1F60F} ${posts[i].author}",
                                                        textAlign: TextAlign.right,
                                                        textScaleFactor: 1.0,
                                                        style: new TextStyle(color: Colors.black.withOpacity(0.6))
                                                    ),
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0)
                                        ),
                                        new Padding(
                                            child:new Text(posts[i].title, 
                                                    style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                                                    textScaleFactor: 1.0,
                                                ),
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0)
                                        ),                                        
                                        const SizedBox(
                                            height: 10.0,
                                        ),
                                        new ButtonTheme.bar(
                                            child: new ButtonBar(
                                                children: <Widget>[
                                                    new FlatButton(
                                                        child: new Text("${posts[i].comments} comments"),
                                                        onPressed: () {
                                                            currentPostId = posts[i].id;
                                                            showComments(context);
                                                        }
                                                    ),
                                                    !posts[i].self ? new FlatButton(
                                                        child: new Text("\u{1F517} Open"),
                                                        onPressed: () {
                                                            if(!posts[i].self)
                                                                launch(posts[i].url);                                                            
                                                        }
                                                    ) : null
                                                ]
                                            )
                                        )
                                    ]
                                )
                            ),
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 0.0)
                    );
                }
            );
        } else {
            return new Center(
                child: new Container(
                    child: new CircularProgressIndicator()
                )
            );
        }
    }

    void reloadMainScreen(BuildContext context) {        
        Navigator.pop(context);
        setState(() {
            posts = [];
            loading = true;
        });
        loadPosts();
    }

    void showComments(BuildContext context) {
        setState(() {
            comments = [];
            loading = true;
        });
        loadComments();
        Navigator.of(context).push(new MaterialPageRoute<Null>(
          builder: (BuildContext context) {
            return new Scaffold(
              appBar: new AppBar(title: new Text('Comments')),
              body: getCommentsPage()
            );
          },
        ));
    }

    Widget getCommentsPage() {
        if(!loading) {
            return new ListView.builder(
                itemCount: comments.length,
                itemBuilder: (BuildContext context, int i) {
                    return new Container(
                        child: new Card(
                                child: new Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                        new Padding(
                                            child: new Text("\u{1F44D} ${comments[i].points}    \u{1F60F} ${comments[i].author}",
                                                        textAlign: TextAlign.right,
                                                        textScaleFactor: 1.0,
                                                        style: new TextStyle(color: Colors.black.withOpacity(0.6))
                                                    ),
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0)
                                        ),
                                        new Padding(
                                            child:new Text(comments[i].text, 
                                                    style: new TextStyle(fontSize: 16.0),
                                                    textScaleFactor: 1.0,
                                                ),
                                            padding: const EdgeInsets.only(left: 16.0, 
                                                                         right: 16.0, top: 16.0, bottom: 16.0)
                                        )                                        
                                    ]
                                )
                            ),
                        padding: new EdgeInsets.only(left: 16.0 + comments[i].depth * 10, 
                                                     right: 16.0, top: comments[i].depth == 0 ? 16.0 : 2.0, bottom: 0.0)
                    );
                }
            );
        } else {
            return new Center(
                child: new Container(
                    child: new CircularProgressIndicator()
                )
            );
        }
    }    
}

class Post {
    String title;
    String author;
    String url;
    String permalink;
    int comments;
    int points;
    String id;
    bool self;
}

class Comment {
    String text;
    String author;
    int points;
    int depth;   
}
