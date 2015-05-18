
var LatestUsers = React.createClass({

  getInitialState: function() {
    return {
      list: [],
      type: null,
      current_path: this.props.path,
      loading: true,
      done: false
    }
  },

  componentDidMount: function() {
    if(this.isMounted()) {
      this.fetchList();
    }
  },

  loadTrending: function() {
    this.setState({loading: true});
    this.setState({current_path: Routes.trending_users_path(), done: false});
    $.getJSON(Routes.trending_users_path(), function(json, textStatus) {
      this.setState({
        list: json.list,
        type: json.type,
        loading: false
      });
    }.bind(this));
  },

  loadPopular: function() {
    this.setState({loading: true});
    this.setState({current_path: Routes.popular_users_path(), done: false});
    $.getJSON(Routes.popular_users_path(), function(json, textStatus) {
      this.setState({
        list: json.list,
        type: json.type,
        loading: false
      });
    }.bind(this));
  },

  resetList: function() {
    this.setState({current_path: Routes.latest_users_path(), done: false, loading: true});
    $.getJSON(Routes.latest_users_path(), function(json, textStatus) {
      this.setState({
        list: json.list,
        type: json.type,
        loading: false
      });
    }.bind(this));
  },

  fetchList: function(){
    $.getJSON(this.state.current_path, function(json, textStatus) {
      this.setState({
        list: json.list,
        type: json.type,
        loading: false
    });
    }.bind(this));
  },

  render: function() {

    var type = this.state.type;
    var users = _.map(this.state.list, function(item){
        return <LatestUsersItem key={Math.random()} type={type} item={item} />;
    });

    if(this.state.loading) {
      var content = <div className="no-content light p-t-40"><i className="fa fa-spinner fa-pulse"></i></div>
    } else {
      var content = users
    }


    return (
      <div className="widget-11-2 panel no-border no-margin bg-white">
          <div className="panel-heading">
           <div className="panel-title">
            {this.state.type}
            </div>
            <div className="panel-controls">
                <ul>
                    <li className="hidden-xlg">
                      <div className="dropdown">
                        <a className="pointer" data-toggle="dropdown" aria-haspopup="true" role="button" aria-expanded="false">
                          <i className="portlet-icon portlet-icon-settings m-r-10"></i>
                        </a>
                        <ul className="dropdown-menu pull-right" role="menu">
                          <li>
                            <a className="pointer" onClick={this.loadTrending}>Trending People</a>
                          </li>
                          <li>
                            <a className="pointer" onClick={this.loadPopular}>Popular People</a>
                          </li>
                        </ul>
                      </div>
                    </li>
                    <li>
                      <a data-toggle="refresh" className="portlet-refresh text-black pointer" onClick={this.resetList}>
                          <i className="portlet-icon portlet-icon-refresh"></i>
                      </a>
                    </li>
                </ul>
            </div>
          </div>
          <div className="panel-body full-border-light full-border-light-bottom no-padding">
            <ul className="trending-list latest-scrollable p-t-10 no-padding no-style no-margin" ref="trendingList">
              {content}
            </ul>
          </div>
      </div>
    );
  }

});