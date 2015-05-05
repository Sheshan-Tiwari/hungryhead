var Friend = React.createClass({

  render: function() {

    if(this.props.friend.avatar) {
      var avatar = <img data-src={this.props.avatar} data-src-retina={this.props.avatar} width="55" height="55" src={this.props.friend.avatar} />;
    } else {
      var avatar =  <span className="placeholder bold text-white" width="32px" height="32px">
                  {this.props.friend.user_name_badge}
             </span>;
    }
    return (
      <li className="p-b-10 p-t-10 b-b b-grey clearfix">
       <div className="followable-info col-md-6 no-padding">
         <div className="thumbnail-wrapper d48 circular bordered b-solid m-r-10">
          {avatar}
         </div>

         <h4 className="no-margin"><a href="">{this.props.friend.name}</a></h4>
         <p>{this.props.friend.mini_bio}</p>
       </div>
       <Follow followed={this.props.friend.followed} />
      </li>
    );
  }
});